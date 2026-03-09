import Foundation
import Observation

@Observable
@MainActor
class AchievementStore {
    var achievements: [Achievement] = []
    var currentStreak: Int = 0
    
    private static let storageKey = "focus-achievements-storage"
    private let calendar = Calendar.current
    
    init() {
        loadAchievements()
    }
    
    private func loadAchievements() {
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode([Achievement].self, from: data) {
            achievements = decoded
        } else {
            achievements = [
                Achievement(id: "1", title: "Novice", description: "Focus for 1 hour", iconName: "timer", goalValue: 60, type: .totalHours),
                Achievement(id: "2", title: "Apprentice", description: "Focus for 10 hours", iconName: "timer.circle.fill", goalValue: 600, type: .totalHours),
                Achievement(id: "3", title: "Master", description: "Focus for 100 hours", iconName: "crown.fill", goalValue: 6000, type: .totalHours),
                Achievement(id: "4", title: "Consistency", description: "3 day streak", iconName: "flame.fill", goalValue: 3, type: .dailyStreak),
                Achievement(id: "5", title: "Dedication", description: "7 day streak", iconName: "flame.circle.fill", goalValue: 7, type: .dailyStreak),
                Achievement(id: "6", title: "Unstoppable", description: "30 day streak", iconName: "trophy.fill", goalValue: 30, type: .dailyStreak)
            ]
        }
    }
    
    func updateProgress(sessions: [FocusSession]) {
        let totalMinutes = sessions.reduce(0) { $0 + $1.duration }
        let totalSessions = sessions.count
        let streak = calculateStreak(from: sessions)
        self.currentStreak = streak
        
        var changed = false
        for i in 0..<achievements.count {
            if !achievements[i].isUnlocked {
                let reachedGoal: Bool
                switch achievements[i].type {
                case .totalHours:   reachedGoal = totalMinutes >= achievements[i].goalValue
                case .dailyStreak:  reachedGoal = streak >= achievements[i].goalValue
                case .sessionsCount: reachedGoal = totalSessions >= achievements[i].goalValue
                }
                
                if reachedGoal {
                    achievements[i].isUnlocked = true
                    achievements[i].unlockDate = Date()
                    changed = true
                }
            }
        }
        
        if changed { save() }
    }
    
    private func calculateStreak(from sessions: [FocusSession]) -> Int {
        guard !sessions.isEmpty else { return 0 }
        let dates = Set(sessions.map { calendar.startOfDay(for: $0.startDate) }).sorted(by: >)
        
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())
        
        // If no session today, check if there was one yesterday to keep streak alive
        if !dates.contains(checkDate) {
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        }
        
        for date in dates {
            if calendar.isDate(date, inSameDayAs: checkDate) {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else if date < checkDate {
                break
            }
        }
        return streak
    }
    
    private func save() {
        if let data = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
}
