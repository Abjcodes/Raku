//
//  RakuApp.swift
//  Raku
//
//  Created by Abijith Vasanthakumar on 03/04/25.
//

import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var timerManager = TimerManager()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        updateMenuBarTitle()
    }
    
    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.title = "20:00"
            button.action = #selector(togglePopover)
        }
        
        setupMenu()
    }
    
    @objc func togglePopover() {
        // This will show the menu when clicked
        setupMenu()
    }
    
    func setupMenu() {
        let menu = NSMenu()
        
        // Timer controls
        menu.addItem(NSMenuItem(title: "Start Timer", action: #selector(startTimer), keyEquivalent: "s"))
        menu.addItem(NSMenuItem(title: "Pause Timer", action: #selector(pauseTimer), keyEquivalent: "p"))
        menu.addItem(NSMenuItem(title: "Reset Timer", action: #selector(resetTimer), keyEquivalent: "r"))
        
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
    }
    
    @objc func pauseTimer() {
        timerManager.pauseTimer()
    }
    
    @objc func resetTimer() {
        timerManager.resetTimer()
    }
    
    @objc func openSettings() {
        // Open settings window
        let settingsWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        settingsWindow.contentView = NSHostingView(rootView: SettingsView(timerManager: timerManager))
        settingsWindow.center()
        settingsWindow.makeKeyAndOrderFront(nil)
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
                }
            }
        }
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
