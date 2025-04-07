import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var timerManager = TimerManager()
    var settingsWindowController: NSWindowController?
    var overlayWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        updateMenuBarTitle()
        
        // Start timer automatically on app launch
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.timerManager.startTimer()
        }
        
        // Subscribe to break start
        timerManager.onBreakStart = { [weak self] in
            self?.showOverlayNotification()
        }
        
        // Subscribe to timer about to end (last 10 seconds)
        timerManager.onTimerAboutToEnd = { [weak self] in
            self?.showOverlayNotification()
        }
        
        // Subscribe to timer completion
        timerManager.onTimerComplete = { [weak self] in
            if let window = self?.overlayWindow, window.isVisible {
                // If notification is still showing, do nothing
            } else {
                // If notification is not showing, start the break
                self?.timerManager.startTimer()
            }
        }
    }
    
    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        setupMenu()  // Just call setupMenu directly
    }
    
    // Remove togglePopover since it's just a wrapper
    func setupMenu() {
        let menu = NSMenu()
        
        // Timer controls - dynamically show based on timer state and mode
        if timerManager.isRunning {
            menu.addItem(NSMenuItem(title: "Pause Timer", action: #selector(pauseTimer), keyEquivalent: "p"))
        } else {
            menu.addItem(NSMenuItem(title: "Resume Timer", action: #selector(startTimer), keyEquivalent: "s"))
        }
        
        menu.addItem(NSMenuItem(title: "Reset Timer", action: #selector(resetTimer), keyEquivalent: "r"))
        
        if timerManager.currentMode != .focus {
            menu.addItem(NSMenuItem(title: "Skip Break", action: #selector(skipBreak), keyEquivalent: "k"))
        }
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    @objc func startTimer() {
        timerManager.startTimer()
        setupMenu()
    }
    
    @objc func pauseTimer() {
        timerManager.pauseTimer()
        setupMenu()
    }
    
    @objc func resetTimer() {
        timerManager.resetTimer()
        setupMenu()
    }
    
    @objc func openSettings() {
        if settingsWindowController == nil {
            let settingsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            settingsWindow.title = "Raku Settings"
            settingsWindow.contentView = NSHostingView(rootView: SettingsView(timerManager: timerManager))
            
            settingsWindowController = NSWindowController(window: settingsWindow)
            settingsWindow.delegate = self
        }
        
        settingsWindowController?.showWindow(nil)
        settingsWindowController?.window?.center()
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    func updateMenuBarTitle() {
        timerManager.onTimerUpdate = { [weak self] remainingTime, showIcon in
            DispatchQueue.main.async {
                if let button = self?.statusItem?.button {
                    if showIcon {
                        let icon = NSImage(named: "RakuMenuIcon")
                        icon?.size = NSSize(width: 18, height: 14)
                        button.image = icon
                        button.imagePosition = .imageLeft
                        button.title = " " + remainingTime
                    } else {
                        button.image = nil
                        button.title = remainingTime
                    }
                    self?.setupMenu()
                }
            }
        }
    }
    
    func showOverlayNotification() {
        let screenSize = NSScreen.main?.frame.size ?? CGSize(width: 800, height: 600)
        let overlaySize = CGSize(width: 420, height: 180)
        let overlayOrigin = CGPoint(x: (screenSize.width - overlaySize.width) / 2, y: screenSize.height - overlaySize.height - 50)
        
        overlayWindow = NSWindow(
            contentRect: NSRect(origin: overlayOrigin, size: overlaySize),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        overlayWindow?.isOpaque = false
        overlayWindow?.backgroundColor = NSColor.clear
        overlayWindow?.level = .floating
        overlayWindow?.hasShadow = false
        
        let isBreakMode = timerManager.currentMode != .focus
        let breakDuration = Double(timerManager.timeRemaining)
        
        let overlayView = NotificationManagerView(
            onDismiss: { [weak self] in
                self?.dismissNotification()
            },
            onAddOneMinute: { [weak self] in
                self?.timerManager.addTime(minutes: 1)
            },
            onAddFiveMinutes: { [weak self] in
                self?.addFiveMinutes()
            },
            onStartBreakTimer: { [weak self] in
                // Dismiss current notification and immediately show break notification
                self?.dismissNotification()
                self?.timerManager.completeCurrentSession()
                self?.showOverlayNotification() // Add this line
            },
            isBreakMode: isBreakMode,
            breakDuration: breakDuration
        )
        
        overlayWindow?.contentView = NSHostingView(rootView: overlayView)
        overlayWindow?.makeKeyAndOrderFront(nil)
    }
}

@main
struct RakuApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        settingsWindowController = nil
    }
    
    @objc func skipBreak() {
        timerManager.skipBreak()
        setupMenu()
    }
}

extension AppDelegate {
    @objc func dismissNotification() {
        overlayWindow?.orderOut(nil)
        overlayWindow = nil
        
        if timerManager.timeRemaining == 0 {
            timerManager.startTimer()
        }
    }
    
    @objc func addOneMinute() {
        timerManager.addTime(minutes: 1)
    }
    
    @objc func addFiveMinutes() {
        timerManager.addTime(minutes: 5)
    }
}
