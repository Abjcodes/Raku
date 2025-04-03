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
        
        // Subscribe to timer completion
        timerManager.onTimerComplete = { [weak self] in
            self?.showOverlayNotification()
        }
    }
    
    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.title = "20m"
            button.action = #selector(togglePopover)
        }
        
        setupMenu()
    }
    
    @objc func togglePopover() {
        setupMenu()
    }
    
    func setupMenu() {
        let menu = NSMenu()
        
        // Timer controls - dynamically show based on timer state and mode
        if timerManager.isRunning {
            // Timer is running - show Pause option
            menu.addItem(NSMenuItem(title: "Pause Timer", action: #selector(pauseTimer), keyEquivalent: "p"))
        } else {
            // Timer is paused - show Resume option
            menu.addItem(NSMenuItem(title: "Resume Timer", action: #selector(startTimer), keyEquivalent: "s"))
        }
        
        // Always show Reset option
        menu.addItem(NSMenuItem(title: "Reset Timer", action: #selector(resetTimer), keyEquivalent: "r"))
        
        // Add Skip Break option if in break mode
        if timerManager.currentMode != .focus {
            menu.addItem(NSMenuItem(title: "Skip Break", action: #selector(skipBreak), keyEquivalent: "k"))
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // Settings
        menu.addItem(NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: ","))
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    @objc func startTimer() {
        timerManager.startTimer()
        setupMenu() // Update menu after starting timer
    }
    
    @objc func pauseTimer() {
        timerManager.pauseTimer()
        setupMenu() // Update menu after pausing timer
    }
    
    @objc func resetTimer() {
        timerManager.resetTimer()
        setupMenu() // Update menu after resetting timer
    }
    
    @objc func openSettings() {
        // Create window controller if none exists
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
        
        // Show window
        settingsWindowController?.showWindow(nil)
        settingsWindowController?.window?.center()
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    func updateMenuBarTitle() {
        // Subscribe to timer updates
        timerManager.onTimerUpdate = { [weak self] remainingTime in
            DispatchQueue.main.async {
                if let button = self?.statusItem?.button {
                    button.title = remainingTime
                    self?.setupMenu() // Update menu on timer updates
                }
            }
        }
    }
    
    func showOverlayNotification() {
        let screenSize = NSScreen.main?.frame.size ?? CGSize(width: 800, height: 600)
        let overlaySize = CGSize(width: 300, height: 120)
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
        overlayWindow?.contentView = NSHostingView(rootView: OverlayView())
        
        overlayWindow?.makeKeyAndOrderFront(nil)
        
        // Wait for 10.3 seconds (10s for timer + 0.3s for exit animation)
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.3) { [weak self] in
            self?.overlayWindow?.orderOut(nil)
            self?.overlayWindow = nil
            
            // Start the break timer instead of resetting
            // The break mode has already been set in TimerManager.completeCurrentSession()
            self?.timerManager.startTimer()
        }
    }
}

struct OverlayView: View {
    @State var yOffset: CGFloat = -150
    @State private var timeRemaining: Double = 10.0 // Changed from 3.0 to 10.0
    @State private var isTimerRunning = true
    
    var body: some View {
        VStack {
            Text("Session Complete!")
                .font(.headline)
                .padding(.top)
            
            Text("Take a break and relax.")
                .font(.subheadline)
                .padding(.bottom, 5)
            
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                    .frame(width: 40, height: 40)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: CGFloat(timeRemaining / 10.0)) // Changed from 3.0 to 10.0
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
                
                // Timer text
                Text("\(Int(timeRemaining))")
                    .font(.system(size: 14, weight: .bold))
            }
            .padding(.bottom, 10)
        }
        .frame(width: 300, height: 120)
        .background(Color.black.opacity(0.8))
        .cornerRadius(10)
        .foregroundColor(.white)
        .offset(y: yOffset)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                yOffset = 0
            }
            
            // Start countdown timer
            startTimer()
        }
    }
    
    private func startTimer() {
        let timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
            if timeRemaining > 0.01 {
                timeRemaining -= 0.01
            } else {
                timer.invalidate()
                isTimerRunning = false
                // Animate out when timer completes
                withAnimation(.easeIn(duration: 0.3)) {
                    yOffset = -150
                }
            }
        }
        RunLoop.current.add(timer, forMode: .common)
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
        setupMenu() // Update menu after skipping break
    }
}
