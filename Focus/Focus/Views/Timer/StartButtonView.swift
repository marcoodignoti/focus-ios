import SwiftUI

struct StartButtonView: View {
    let label: String
    let onPress: () -> Void

    var body: some View {
        Button(action: onPress) {
            Text(label)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .padding(.vertical, 16)
                .padding(.horizontal, 24)
                .glassBackground(in: Capsule())
        }
        .buttonStyle(SpringButtonStyle())
        .accessibilityLabel(label)
        .accessibilityHint("Starts the focus timer")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: – Spring press style

private struct SpringButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

