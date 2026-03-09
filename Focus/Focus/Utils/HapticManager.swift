import UIKit

/// Manages haptic feedback for the application.
/// Pre-prepares generators to ensure minimal latency when feedback is triggered.
@MainActor
enum HapticManager {
    private static let selectionGenerator = UISelectionFeedbackGenerator()
    private static let lightImpactGenerator = UIImpactFeedbackGenerator(style: .light)
    private static let mediumImpactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private static let notificationGenerator = UINotificationFeedbackGenerator()

    static func selection() {
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare()
    }

    static func impactLight() {
        lightImpactGenerator.impactOccurred()
        lightImpactGenerator.prepare()
    }

    static func impactMedium() {
        mediumImpactGenerator.impactOccurred()
        mediumImpactGenerator.prepare()
    }

    static func notifySuccess() {
        notificationGenerator.notificationOccurred(.success)
        notificationGenerator.prepare()
    }

    static func notifyWarning() {
        notificationGenerator.notificationOccurred(.warning)
        notificationGenerator.prepare()
    }

    /// Call this to pre-warm generators when a view appears.
    static func prepare() {
        selectionGenerator.prepare()
        lightImpactGenerator.prepare()
        mediumImpactGenerator.prepare()
        notificationGenerator.prepare()
    }
}
