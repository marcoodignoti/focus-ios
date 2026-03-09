import SwiftUI

struct AchievementUnlockOverlay: View {
    let achievement: Achievement
    let onFinished: () -> Void
    
    @State private var isAnimating = false
    @State private var showContent = false
    
    var body: some View {
        ZStack {
            // Dark dim background
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture { finish() }
            
            VStack(spacing: 30) {
                // Celebration Title
                Text("ACHIEVEMENT UNLOCKED!")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .tracking(3)
                    .foregroundStyle(.orange)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                
                // Animated Badge
                ZStack {
                    // Radiant Glow
                    Circle()
                        .fill(Color.orange.opacity(0.4))
                        .frame(width: 200, height: 200)
                        .blur(radius: 40)
                        .scaleEffect(isAnimating ? 1.4 : 0.6)
                        .opacity(isAnimating ? 0.8 : 0.2)
                    
                    BadgeView(achievement: achievement)
                        .scaleEffect(isAnimating ? 1.5 : 0.1)
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))
                }
                
                VStack(spacing: 12) {
                    Text(achievement.title)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text(achievement.description)
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 30)
                
                Button {
                    finish()
                } label: {
                    Text("Awesome!")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 16)
                        .background(.orange)
                        .clipShape(Capsule())
                }
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.8)
            }
        }
        .onAppear {
            HapticManager.notifySuccess()
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isAnimating = true
            }
            
            withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
                showContent = true
            }
        }
    }
    
    private func finish() {
        withAnimation(.easeIn(duration: 0.3)) {
            isAnimating = false
            showContent = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onFinished()
        }
    }
}
