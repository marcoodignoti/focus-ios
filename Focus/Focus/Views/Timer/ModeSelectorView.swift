import SwiftUI

struct ModeSelectorView: View {
    let mode: FocusMode
    let onPress: () -> Void

    var body: some View {
        Button(action: onPress) {
            HStack(spacing: 8) {
                // Icon badge
                ZStack {
                    Circle()
                        .fill(Color(hex: "#353B60").opacity(0.8))
                        .frame(width: 36, height: 36)
                    Image(systemName: sfSymbol(for: mode.icon))
                        .font(.system(size: 16))
                        .foregroundColor(getIconColor(mode.icon).opacity(0.9))
                }

                Text(mode.name)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(2)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .glassBackground(in: Capsule())
        }
        .buttonStyle(SpringButtonStyle())
    }
}

// MARK: – Spring button style

private struct SpringButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(
                x: configuration.isPressed ? 0.95 : 1.0,
                y: configuration.isPressed ? 0.92 : 1.0
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
