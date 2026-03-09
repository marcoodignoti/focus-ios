import Foundation
import Observation

@Observable
@MainActor
class FocusHistoryStore {

    var sessions: [FocusSession]

    private static let storageKey = "focus-history-storage"
    private let queue = DispatchQueue(label: "com.focus.history.persistence", qos: .background)

    init() {
        if let data    = UserDefaults.standard.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode([FocusSession].self, from: data) {
            sessions = decoded
        } else {
            sessions = []
        }
    }

    // MARK: – Persistence

    private func save() {
        let sessionsToSave = sessions // Capture current state
        queue.async {
            if let data = try? JSONEncoder().encode(sessionsToSave) {
                UserDefaults.standard.set(data, forKey: Self.storageKey)
            }
        }
    }

    // MARK: – Actions

    func addSession(modeId: String,
                    modeTitle: String,
                    color: String,
                    startTime: Double,
                    duration: Int) {
        let session = FocusSession(
            id:        "\(Int(Date().timeIntervalSince1970 * 1000))",
            modeId:    modeId,
            modeTitle: modeTitle,
            color:     color,
            startTime: startTime,
            duration:  duration
        )
        sessions.append(session)
        save()
    }

    func deleteSession(id: String) {
        sessions.removeAll { $0.id == id }
        save()
    }

    func clearHistory() {
        sessions = []
        save()
    }
}
