import Foundation
import SwiftUI
import UserNotifications
import AppKit

enum PomodoroPhase {
    case focus
    case shortBreak
    case longBreak
}

class PomodoroManager: ObservableObject {
    // Available system sounds
    static let availableSounds = [
        "Glass", "Basso", "Blow", "Bottle", "Frog", "Funk", 
        "Hero", "Morse", "Ping", "Pop", "Purr", "Sosumi", 
        "Submarine", "Tink"
    ]
    
    @Published var timeRemaining: Int = 20 * 60 // 20 minutes in seconds
    @Published var isRunning: Bool = false
    @Published var currentPhase: PomodoroPhase = .focus
    @Published var completedFocusSessions: Int = 0
    @Published var completedShortBreaks: Int = 0
    
    // Settings
    @Published var focusDuration: Int = 20 * 60 // 20 minutes
    @Published var shortBreakDuration: Int = 2 * 60 // 2 minutes
    @Published var longBreakDuration: Int = 15 * 60 // 15 minutes
    @Published var sessionsBeforeLongBreak: Int = 4
    @Published var selectedSound: String = "Glass" // System sound name
    
    // Daily reset tracking
    private var lastResetDate: Date = Date()
    
    // Session tracking for proper cycling
    private var currentSessionNumber: Int = 1
    
    // Cached values to reduce computation
    private var cachedFormattedTime: String = "20:00"
    private var cachedProgress: Double = 0.0
    private var cachedPhaseTitle: String = "Focus"
    private var lastTimeRemaining: Int = 20 * 60
    private var lastPhase: PomodoroPhase = .focus
    
    init() {
        checkDailyReset()
        updateCachedValues()
    }
    
    var formattedTime: String {
        // Only recalculate if time has changed
        if timeRemaining != lastTimeRemaining {
            let minutes = timeRemaining / 60
            let seconds = timeRemaining % 60
            cachedFormattedTime = String(format: "%02d:%02d", minutes, seconds)
            lastTimeRemaining = timeRemaining
        }
        return cachedFormattedTime
    }
    
    var phaseTitle: String {
        // Only recalculate if phase has changed
        if currentPhase != lastPhase {
            switch currentPhase {
            case .focus:
                cachedPhaseTitle = "Focus"
            case .shortBreak:
                cachedPhaseTitle = "Short Break"
            case .longBreak:
                cachedPhaseTitle = "Long Break"
            }
            lastPhase = currentPhase
        }
        return cachedPhaseTitle
    }
    
    var progress: Double {
        // Only recalculate if time or phase has changed
        if timeRemaining != lastTimeRemaining || currentPhase != lastPhase {
            let totalTime: Int
            switch currentPhase {
            case .focus:
                totalTime = focusDuration
            case .shortBreak:
                totalTime = shortBreakDuration
            case .longBreak:
                totalTime = longBreakDuration
            }
            cachedProgress = 1.0 - (Double(timeRemaining) / Double(totalTime))
            lastTimeRemaining = timeRemaining
            lastPhase = currentPhase
        }
        return cachedProgress
    }
    
    private func updateCachedValues() {
        // Force update of all cached values
        _ = formattedTime
        _ = phaseTitle
        _ = progress
    }
    
    func toggleTimer() {
        if isRunning {
            pauseTimer()
        } else {
            startTimer()
        }
    }
    
    func startTimer() {
        checkDailyReset()
        isRunning = true
    }
    
    func pauseTimer() {
        isRunning = false
    }
    
    func resetTimer() {
        pauseTimer()
        timeRemaining = getCurrentPhaseDuration()
        updateCachedValues()
    }
    
    func updateTimer() {
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            timerCompleted()
        }
    }
    
    func skipToNextPhase() {
        pauseTimer()
        transitionToNextPhase(skip: true)
    }
    
    private func transitionToNextPhase(skip: Bool = false) {
        switch currentPhase {
        case .focus:
            if !skip {
                completedFocusSessions += 1
            }
            currentSessionNumber += 1
            
            if currentSessionNumber > sessionsBeforeLongBreak {
                currentPhase = .longBreak
                timeRemaining = longBreakDuration
                currentSessionNumber = 1 // Reset for next cycle
            } else {
                currentPhase = .shortBreak
                timeRemaining = shortBreakDuration
            }
            
        case .shortBreak:
            if !skip {
                completedShortBreaks += 1
            }
            currentPhase = .focus
            timeRemaining = focusDuration
            
        case .longBreak:
            currentPhase = .focus
            timeRemaining = focusDuration
        }
        
        // Update cached values after phase change
        updateCachedValues()
        
        // Only show notification if not skipping
        if !skip {
            showNotification()
        }
    }
    
    func timerCompleted() {
        pauseTimer()
        transitionToNextPhase(skip: false)
    }
    
    func getCurrentPhaseDuration() -> Int {
        switch currentPhase {
        case .focus:
            return focusDuration
        case .shortBreak:
            return shortBreakDuration
        case .longBreak:
            return longBreakDuration
        }
    }
    
    func showNotification() {
        // Play a more pronounced sound for session completion
        playPronouncedSound()
    }
    
    private func playPronouncedSound() {
        // Use system sound for better audio quality
        if let sound = NSSound(named: selectedSound) {
            sound.play()
        } else {
            // Fallback to default sound if selected sound is not available
            if let defaultSound = NSSound(named: "Glass") {
                defaultSound.play()
            } else {
                // Final fallback to beep
                NSSound.beep()
            }
        }
    }
    
    func resetSession() {
        pauseTimer()
        completedFocusSessions = 0
        completedShortBreaks = 0
        currentSessionNumber = 1
        currentPhase = .focus
        timeRemaining = focusDuration
        updateCachedValues()
    }
    
    func checkDailyReset() {
        let calendar = Calendar.current
        let today = Date()
        
        // Check if the last reset was on a different day
        if !calendar.isDate(lastResetDate, inSameDayAs: today) {
            resetDailyCounters()
        }
    }
    
    private func resetDailyCounters() {
        completedFocusSessions = 0
        completedShortBreaks = 0
        currentSessionNumber = 1
        lastResetDate = Date()
    }
} 