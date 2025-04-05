import Foundation
import AppKit

// Define timer modes
enum TimerMode {
    case focus
    case shortBreak
    case longBreak
}

class TimerManager: ObservableObject {
    @Published var timeRemaining: Int = 20 * 60
    @Published var isRunning: Bool = false
    @Published var currentMode: TimerMode = .focus
    
    // Session durations
    private var focusDuration: Int = 20 * 60
    private var shortBreakDuration: Int = 30
    private var longBreakDuration: Int = 15 * 60
    
    // Session tracking
    private var completedSessions: Int = 0
    private var sessionsUntilLongBreak: Int = 4
    
    private var timer: Timer?
    private var inactivityTimer: Timer?
    private var inactivityThreshold: TimeInterval = 1 * 60
    private var lastActivityTime: Date = Date()
    private var wasAutoPaused: Bool = false
    
    // Modify the callback type to include both text and whether to show icon
    var onTimerUpdate: ((String, Bool) -> Void)?
    var onTimerComplete: (() -> Void)?
    var onBreakStart: (() -> Void)?
    var onTimerAboutToEnd: (() -> Void)?  // Add this new property

    init() {
        updateTimerDisplay()
        setupInactivityMonitoring()
    }
    
    // Setup monitoring for user activity
    private func setupInactivityMonitoring() {
        // Check for inactivity more frequently (every 1 second)
        inactivityTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.checkForInactivity()
        }
        
        // Register for workspace notifications to detect user activity
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(userDidBecomeActive),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
        
        // Also monitor mouse and keyboard activity
        NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDown, .rightMouseDown, .keyDown]) { [weak self] _ in
            self?.userDidBecomeActive()
        }
    }
    
    @objc private func userDidBecomeActive() {
        let currentTime = Date()
        lastActivityTime = currentTime
        
        // If timer was paused due to inactivity, resume it
        if !isRunning && timeRemaining > 0 && wasAutoPaused {
            startTimer()
            wasAutoPaused = false
        }
    }
    
    private func checkForInactivity() {
        guard isRunning else { return }
        
        let currentTime = Date()
        let timeSinceLastActivity = currentTime.timeIntervalSince(lastActivityTime)
        
        if timeSinceLastActivity >= inactivityThreshold {
            // User has been inactive for longer than the threshold
            wasAutoPaused = true
            pauseTimer()
        }
    }
    
    func startTimer() {
        guard !isRunning else { return }
        
        // Reset activity tracking when starting timer
        lastActivityTime = Date()
        
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.timeRemaining > 0 {
                // Check if we're in the last 59 seconds of a focus session
                if self.currentMode == .focus && self.timeRemaining == 59 {
                    self.onTimerAboutToEnd?()
                }
                
                self.timeRemaining -= 1
                self.updateTimerDisplay()
            } else {
                self.pauseTimer()
                self.completeCurrentSession()
            }
        }
    }
    
    func completeCurrentSession() {
        switch currentMode {
        case .focus:
            // When focus session completes
            completedSessions += 1
            onTimerComplete?() // Call notification here for focus completion
            
            // Determine which break type to start
            if completedSessions % sessionsUntilLongBreak == 0 {
                switchToMode(.longBreak)
            } else {
                switchToMode(.shortBreak)
            }
            startTimer() // Start break timer automatically
            
        case .shortBreak, .longBreak:
            // After a break, go back to focus mode
            switchToMode(.focus)
            startTimer()
        }
    }
    
    func switchToMode(_ mode: TimerMode) {
        currentMode = mode
        
        // Set appropriate duration based on mode
        switch mode {
        case .focus:
            timeRemaining = focusDuration
        case .shortBreak:
            timeRemaining = shortBreakDuration
            onTimerAboutToEnd?() // Show notification at start of break
        case .longBreak:
            timeRemaining = longBreakDuration
            onTimerAboutToEnd?() // Show notification at start of break
        }
        
        updateTimerDisplay()
    }
    
    func pauseTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        updateTimerDisplay()
    }
    
    func resetTimer() {
        pauseTimer()
        switchToMode(.focus)
        completedSessions = 0
    }
    
    func skipBreak() {
        if currentMode == .shortBreak || currentMode == .longBreak {
            switchToMode(.focus)
            pauseTimer()
        }
    }
    
    private func updateTimerDisplay() {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        
        // Show only minutes when more than 60 seconds remain
        // Show only seconds for the last minute
        var timeString: String
        if timeRemaining > 59 {
            timeString = "\(minutes)m"
        } else {
            timeString = "\(seconds)s"
        }
        
        // Add mode indicator
        let modePrefix: String
        if !isRunning && timeRemaining > 0 {
            if wasAutoPaused {
                modePrefix = "Idle "
            } else {
                modePrefix = "Paused "
            }
        } else {
            switch currentMode {
            case .focus:
                modePrefix = ""  // No prefix for focus mode
            case .shortBreak:
                modePrefix = "Break "
            case .longBreak:
                modePrefix = "Long Break "
            }
        }
        
        timeString = modePrefix + timeString
        onTimerUpdate?(timeString, true)  // Added boolean parameter for showing icon
    }
    
    func setCustomTime(minutes: Int) {
        focusDuration = minutes * 60
        
        // Update current timer if we're in focus mode
        if currentMode == .focus {
            timeRemaining = focusDuration
            updateTimerDisplay()
        }
    }
    
    func setShortBreakDuration(minutes: Int) {
        shortBreakDuration = minutes * 60
        
        // Update current timer if we're in short break mode
        if currentMode == .shortBreak {
            timeRemaining = shortBreakDuration
            updateTimerDisplay()
        }
    }
    
    func setLongBreakDuration(minutes: Int) {
        longBreakDuration = minutes * 60
        
        // Update current timer if we're in long break mode
        if currentMode == .longBreak {
            timeRemaining = longBreakDuration
            updateTimerDisplay()
        }
    }
    
    func setSessionsUntilLongBreak(sessions: Int) {
        sessionsUntilLongBreak = max(1, sessions)
    }
    
    // Add this method to the TimerManager class
    func addTime(minutes: Int) {
        timeRemaining += minutes * 60
        updateTimerDisplay()
    }
}

