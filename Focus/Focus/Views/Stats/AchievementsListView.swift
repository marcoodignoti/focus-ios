import SwiftUI

struct AchievementsListView: View {
    @Environment(AchievementStore.self) private var achievementStore
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#111116").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Summary Stats
                        HStack(spacing: 20) {
                            statBox(title: "Streak", value: "\(achievementStore.currentStreak)", icon: "flame.fill", color: .orange)
                            statBox(title: "Unlocked", value: "\(achievementStore.achievements.filter { $0.isUnlocked }.count)/\(achievementStore.achievements.count)", icon: "trophy.fill", color: .yellow)
                        }
                        .padding(.top, 20)
                        
                        // Grid
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 20),
                            GridItem(.flexible(), spacing: 20),
                            GridItem(.flexible(), spacing: 20)
                        ], spacing: 30) {
                            ForEach(achievementStore.achievements) { achievement in
                                BadgeView(achievement: achievement)
                            }
                        }
                        .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.orange)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func statBox(title: String, value: String, icon: String, color: Color) -> some View {
        GlassCard(cornerRadius: 20) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.system(size: 20))
                
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
    }
}
