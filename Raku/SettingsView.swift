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
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Spacer()
                        Image("RakuIcon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                        Spacer()
                    }
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
        }
        .frame(width: 300, height: 320)
        .padding()
        .onAppear {
            // Initialize the sliders with the current timer values
            focusDuration = Double(timerManager.timeRemaining / 60)
        }
    }
}

