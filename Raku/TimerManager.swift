//
//  TimerManager.swift
//  Raku
//
//  Created by Abijith Vasanthakumar on 04/04/25.
//

import Foundation

class TimerManager: ObservableObject {
    @Published var timeRemaining: Int = 20 * 60 // 20 minutes in seconds
    @Published var isRunning: Bool = false
    
    private var timer: Timer?
    var onTimerUpdate: ((String) -> Void)?
    
    init() {
        updateTimerDisplay()
    }
    
    func startTimer() {
        guard !isRunning else { return }
        
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
                self.updateTimerDisplay()
            } else {
                self.pauseTimer()
                // Here you would trigger a break notification
            }
        }
    }
    
    func pauseTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    func resetTimer() {
        pauseTimer()
        timeRemaining = 20 * 60
        updateTimerDisplay()
    }
    
    private func updateTimerDisplay() {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        let timeString = String(format: "%02d:%02d", minutes, seconds)
        onTimerUpdate?(timeString)
    }
    
    func setCustomTime(minutes: Int) {
        timeRemaining = minutes * 60
        updateTimerDisplay()
    }
}

