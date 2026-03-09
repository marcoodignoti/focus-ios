import SwiftUI

struct BadgeView: View {
    let achievement: Achievement
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                // Glow effect for unlocked
                if achievement.isUnlocked {
                    Circle()
                        .fill(Color.orange.opacity(0.3))
                        .blur(radius: isAnimating ? 15 : 5)
                        .scaleEffect(isAnimating ? 1.2 : 0.8)
                }
                
                Circle()
                    .fill(achievement.isUnlocked ? .white.opacity(0.15) : .white.opacity(0.05))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .stroke(achievement.isUnlocked ? .orange.opacity(0.5) : .white.opacity(0.1), lineWidth: 2)
                    )
                
                Image(systemName: achievement.iconName)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(achievement.isUnlocked ? 
                                     AnyShapeStyle(LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing)) :
                                     AnyShapeStyle(LinearGradient(colors: [.white.opacity(0.2), .white.opacity(0.1)], startPoint: .top, endPoint: .bottom)))
                    .symbolEffect(.bounce, value: isAnimating)
            }
            .onAppear {
                if achievement.isUnlocked {
                    withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                        isAnimating = true
                    }
                }
            }
            
            VStack(spacing: 4) {
                Text(achievement.title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(achievement.isUnlocked ? .white : .white.opacity(0.4))
                
                Text(achievement.description)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.3))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(width: 100)
        }
    }
}
