import SwiftUI

/// A rounded glass-effect card with support for Liquid Glass (iOS 26+)
/// and a high-quality material fallback for older versions.
struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat
    var content: () -> Content

    init(cornerRadius: CGFloat = 24, @ViewBuilder content: @escaping () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content
    }

    var body: some View {
        content()
            .glassBackground(in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}
