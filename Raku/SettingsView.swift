//
//  SettingsView.swift
//  Raku
//
//  Created by Abijith Vasanthakumar on 04/04/25.
//

import SwiftUI
import AppKit

struct SettingsView: View {
    @ObservedObject var timerManager: TimerManager
    @State private var breakDuration: Double = 20
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Raku Settings")
                .font(.headline)
            
            VStack(alignment: .leading) {
                Text("Break Duration: \(Int(breakDuration)) minutes")
                Slider(value: $breakDuration, in: 1...60, step: 1)
                    .onChange(of: breakDuration) { newValue in
                        // Apply changes immediately but don't close the window
                        timerManager.setCustomTime(minutes: Int(newValue))
                    }
            }
            .padding()
            
            Button("Close") {
                // Use NSApp.windows instead and close window more safely
                for window in NSApp.windows {
                    if window.isVisible && window.contentView is NSHostingView<SettingsView> {
                        window.orderOut(nil)
                        return
                    }
                }
            }
            .keyboardShortcut(.defaultAction)
        }
        .frame(width: 300, height: 200)
        .padding()
        .onAppear {
            // Initialize the slider with the current timer value
            breakDuration = Double(timerManager.timeRemaining / 60)
        }
    }
}

