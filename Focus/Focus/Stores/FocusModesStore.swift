import Foundation
import Observation

struct ModeUpdates {
    var name: String?
    var duration: Int?
    var icon: String?
}

// Persistence container for UserDefaults
private struct FocusModesPersistence: Codable {
    var modes: [FocusMode]
    var defaultModeId: String
    var currentMode: FocusMode
    var pomodoroState: PomodoroState
}

@Observable
@MainActor
class FocusModesStore {

    var modes: [FocusMode]
    var defaultModeId: String
    var currentMode: FocusMode
    var timerResetKey: Int = 0
    var pomodoroState: PomodoroState

    private static let storageKey = "focus-modes-storage"

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode(FocusModesPersistence.self, from: data) {
            modes        = decoded.modes
            defaultModeId = decoded.defaultModeId
            currentMode  = decoded.currentMode
            pomodoroState = decoded.pomodoroState
        } else {
            let defaults  = FocusMode.defaults
            modes         = defaults
            defaultModeId = defaults[0].id
            currentMode   = defaults[0]
            pomodoroState = .initial
        }
    }

    // MARK: – Persistence

    private func save() {
        let p = FocusModesPersistence(
            modes:         modes,
            defaultModeId: defaultModeId,
            currentMode:   currentMode,
            pomodoroState: pomodoroState
        )
        if let data = try? JSONEncoder().encode(p) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    // MARK: – Actions

    func setCurrentMode(_ mode: FocusMode) {
        currentMode = mode
        save()
    }

    func resetTimer() {
        timerResetKey += 1
    }

    func updateModeParams(id: String, updates: ModeUpdates) {
        modes = modes.map { m in
            guard m.id == id else { return m }
            var updated = m
            if let name     = updates.name     { updated.name     = name }
            if let duration = updates.duration { updated.duration = duration }
            if let icon     = updates.icon     { updated.icon     = icon }
            return updated
        }
        if currentMode.id == id {
            var updated = currentMode
            if let name     = updates.name     { updated.name     = name }
            if let duration = updates.duration { updated.duration = duration }
            if let icon     = updates.icon     { updated.icon     = icon }
            currentMode = updated
            timerResetKey += 1
        }
        save()
    }

    func setDefaultMode(id: String, isActive: Bool) {
        defaultModeId = id
        if !isActive, let mode = modes.first(where: { $0.id == id }) {
            currentMode  = mode
            timerResetKey += 1
        }
        save()
    }

    func deleteMode(id: String, isActive: Bool) {
        let remaining = modes.filter { $0.id != id }
        guard !remaining.isEmpty else { return }
        modes = remaining
        if currentMode.id == id {
            currentMode   = remaining[0]
            timerResetKey += 1
        }
        if defaultModeId == id {
            defaultModeId = remaining[0].id
        }
        save()
    }

    func createMode(name: String, duration: Int, icon: String) {
        let maxId  = modes.compactMap { Int($0.id) }.max() ?? 0
        let newMode = FocusMode(id: "\(maxId + 1)", name: name, duration: duration, icon: icon)
        modes.append(newMode)
        save()
    }

    func nextPomodoroPhase() {
        let current = pomodoroState
        var nextPhase: PomodoroPhase = .focus
        var nextCount = current.sessionCount

        switch current.phase {
        case .focus:
            nextPhase = current.sessionCount < 4 ? .shortBreak : .longBreak
        case .shortBreak:
            nextPhase = .focus
            nextCount = current.sessionCount + 1
        case .longBreak:
            nextPhase = .focus
            nextCount  = 1
        }

        pomodoroState = PomodoroState(phase: nextPhase, sessionCount: nextCount)
        timerResetKey += 1
        save()
    }

    func resetPomodoro() {
        pomodoroState = .initial
        save()
    }
}
