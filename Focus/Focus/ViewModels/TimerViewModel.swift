import Foundation
import Observation
import Combine
import SwiftUI

@Observable
@MainActor
final class TimerViewModel {
    // Dependencies
    private var modesStore: FocusModesStore
    private var historyStore: FocusHistoryStore
    
    // Timer state
    var isActive = false
    var isPaused = false
    var timeRemaining: Double = 0
    var sessionStartTime: Date? = nil
    var timeElapsedBeforePause: TimeInterval = 0
    var accumulatedMinutes = 0
    
    // Hold-to-stop
    var holdProgress: Double = 0
    var isHolding = false
    private var holdTimer: Timer? = nil
    
    // Ticker
    private var cancellables = Set<AnyCancellable>()
    private let ticker = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    init(modesStore: FocusModesStore, historyStore: FocusHistoryStore) {
        self.modesStore = modesStore
        self.historyStore = historyStore
        self.timeRemaining = calculateDuration()
        setupTicker()
    }
    
    func calculateDuration() -> Double {
        let fs = Double(modesStore.currentMode.duration * 60)
        switch modesStore.pomodoroState.phase {
        case .focus:      return fs
        case .shortBreak:
            let b = fs * 0.2
            return b > 60 ? (ceil(b / 60) * 60) : ceil(b)
        case .longBreak:
            let b = fs * 0.6
            return b > 60 ? (ceil(b / 60) * 60) : ceil(b)
        }
    }
    
    private func setupTicker() {
        ticker.sink { [weak self] _ in
            self?.tick()
        }
        .store(in: &cancellables)
    }
    
    private func tick() {
        guard isActive, !isPaused, let start = sessionStartTime else { return }
        
        let elapsedSinceStart = Date().timeIntervalSince(start)
        let totalElapsed = timeElapsedBeforePause + elapsedSinceStart
        let total = calculateDuration()
        
        if totalElapsed < total {
            timeRemaining = total - totalElapsed
        } else {
            timeRemaining = 0
            handleTimerComplete()
        }
    }
    
    func startFocus() {
        HapticManager.impactMedium()
        sessionStartTime = Date()
        timeElapsedBeforePause = 0
        isActive = true
        isPaused = false
        timeRemaining = calculateDuration()
        accumulatedMinutes = 0
    }
    
    func pauseFocus() {
        HapticManager.impactLight()
        if let start = sessionStartTime {
            timeElapsedBeforePause += Date().timeIntervalSince(start)
        }
        sessionStartTime = nil
        isPaused = true
    }
    
    func resumeFocus() {
        HapticManager.impactLight()
        sessionStartTime = Date()
        isPaused = false
    }
    
    func stopFocus() {
        saveAccumulatedSession()
        isActive = false
        isPaused = false
        sessionStartTime = nil
        timeElapsedBeforePause = 0
        modesStore.resetTimer()
        modesStore.resetPomodoro()
    }
    
    private func saveAccumulatedSession() {
        guard accumulatedMinutes > 0 else { return }
        let start = Date().addingTimeInterval(-Double(accumulatedMinutes * 60))
        
        historyStore.addSession(
            modeId:    modesStore.currentMode.id,
            modeTitle: modesStore.currentMode.name,
            color:     getIconColorHex(modesStore.currentMode.icon),
            startTime: start.timeIntervalSince1970 * 1000,
            duration:  accumulatedMinutes
        )
        accumulatedMinutes = 0
    }
    
    private func handleTimerComplete() {
        HapticManager.notifySuccess()

        if modesStore.pomodoroState.phase == .focus {
            accumulatedMinutes += modesStore.currentMode.duration
        }
        if modesStore.pomodoroState.phase == .longBreak {
            saveAccumulatedSession()
        }

        modesStore.nextPomodoroPhase()
        sessionStartTime = Date() 
        timeElapsedBeforePause = 0
        isActive = true
        isPaused = false
        timeRemaining = calculateDuration()
    }
    
    // MARK: - Hold to Stop Logic
    
    func beginHold() {
        isHolding = true
        holdProgress = 0
        HapticManager.impactLight()

        let startTime = Date()
        let duration: Double = 2.0

        holdTimer = Timer.scheduledTimer(withTimeInterval: 1 / 60.0, repeats: true) { [weak self] t in
            guard let self = self else { t.invalidate(); return }
            
            Task { @MainActor in
                guard self.isHolding else { t.invalidate(); return }
                let elapsed = Date().timeIntervalSince(startTime)
                let progress = min(elapsed / duration, 1.0)
                
                withAnimation(.linear(duration: 0.05)) {
                    self.holdProgress = progress
                }
                
                if progress >= 1.0 {
                    t.invalidate()
                    HapticManager.notifyWarning()
                    self.stopFocus()
                    self.isHolding = false
                    self.holdProgress = 0
                }
            }
        }
    }
    
    func cancelHold() {
        isHolding = false
        holdTimer?.invalidate()
        holdTimer = nil
        withAnimation(.easeOut(duration: 0.3)) {
            holdProgress = 0
        }
    }
    
    func resetDuration() {
        if !isActive {
            timeRemaining = calculateDuration()
        }
    }
}
