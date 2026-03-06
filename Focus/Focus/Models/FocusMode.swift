import Foundation

/// Represents a configured focus activity.
struct FocusMode: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var duration: Int  // minutes
    var icon: String   // icon key (maps to SF Symbol via Constants)

    static let defaults: [FocusMode] = [
        FocusMode(id: "1", name: "Study",   duration: 35, icon: "book"),
        FocusMode(id: "2", name: "Work",    duration: 45, icon: "briefcase"),
        FocusMode(id: "3", name: "Focus",   duration: 15, icon: "cafe"),
        FocusMode(id: "4", name: "Fitness", duration: 45, icon: "barbell"),
        FocusMode(id: "5", name: "Read",    duration: 20, icon: "library"),
    ]
}

/// The different phases of a Pomodoro cycle.
enum PomodoroPhase: String, Codable, CaseIterable {
    case focus
    case shortBreak
    case longBreak

    var displayName: String {
        switch self {
        case .focus:      "Focus"
        case .shortBreak: "Short Break"
        case .longBreak:  "Long Break"
        }
    }
}

/// Current state of the Pomodoro cycle.
struct PomodoroState: Codable, Equatable {
    var phase: PomodoroPhase
    var sessionCount: Int  // 1 to 4

    static let initial = PomodoroState(phase: .focus, sessionCount: 1)
}
