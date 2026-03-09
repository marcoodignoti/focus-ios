import Foundation

struct Achievement: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let iconName: String
    let goalValue: Int
    let type: AchievementType
    var isUnlocked: Bool = false
    var unlockDate: Date? = nil
    
    enum AchievementType: String, Codable {
        case totalHours
        case dailyStreak
        case sessionsCount
    }
}

struct AchievementProgress {
    let currentStreak: Int
    let totalMinutes: Int
    let totalSessions: Int
}
