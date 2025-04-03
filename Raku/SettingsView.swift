import SwiftUI
import AppKit

struct SettingsView: View {
    @ObservedObject var timerManager: TimerManager
    @State private var focusDuration: Double = 20
    @State private var shortBreakDuration: Double = 5
    @State private var longBreakDuration: Double = 15
    @State private var sessionsUntilLongBreak: Double = 4
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Raku Settings")
                .font(.headline)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    // Focus duration
                    VStack(alignment: .leading) {
                        Text("Focus Duration: \(Int(focusDuration)) minutes")
                        Slider(value: $focusDuration, in: 1...60, step: 1)
                            .onChange(of: focusDuration) { oldValue, newValue in
                                timerManager.setCustomTime(minutes: Int(newValue))
                            }
                    }
                    
                    // Short break duration
                    VStack(alignment: .leading) {
                        Text("Short Break: \(Int(shortBreakDuration)) minutes")
                        Slider(value: $shortBreakDuration, in: 1...30, step: 1)
                            .onChange(of: shortBreakDuration) { oldValue, newValue in
                                timerManager.setShortBreakDuration(minutes: Int(newValue))
                            }
                    }
                    
                    // Long break duration
                    VStack(alignment: .leading) {
                        Text("Long Break: \(Int(longBreakDuration)) minutes")
                        Slider(value: $longBreakDuration, in: 5...60, step: 1)
                            .onChange(of: longBreakDuration) { oldValue, newValue in
                                timerManager.setLongBreakDuration(minutes: Int(newValue))
                            }
                    }
                    
                    // Sessions until long break
                    VStack(alignment: .leading) {
                        Text("Sessions until long break: \(Int(sessionsUntilLongBreak))")
                        Slider(value: $sessionsUntilLongBreak, in: 1...10, step: 1)
                            .onChange(of: sessionsUntilLongBreak) { oldValue, newValue in
                                timerManager.setSessionsUntilLongBreak(sessions: Int(newValue))
                            }
                    }
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
        .frame(width: 300, height: 300)
        .padding()
        .onAppear {
            // Initialize the sliders with the current timer values
            focusDuration = Double(timerManager.timeRemaining / 60)
        }
    }
}

