import SwiftUI

// MARK: – Icon key → SF Symbol name

let ICON_SF_SYMBOLS: [String: String] = [
    "book":            "book.fill",
    "briefcase":       "briefcase.fill",
    "fitness":         "figure.run",
    "barbell":         "dumbbell.fill",
    "library":         "building.columns.fill",
    "code-slash":      "chevron.left.forwardslash.chevron.right",
    "laptop":          "laptopcomputer",
    "moon":            "moon.fill",
    "sunny":           "sun.max.fill",
    "cafe":            "cup.and.saucer.fill",
    "leaf":            "leaf.fill",
    "musical-notes":   "music.note",
    "pencil":          "pencil",
    "brush":           "paintbrush.fill",
    "calculator":      "function",
    "game-controller": "gamecontroller.fill",
    // fallback for new-mode default
    "flash":           "bolt.fill",
]

// MARK: – Icon key → accent Color

let ICON_COLORS: [String: Color] = [
    "book":            Color(hex: "#0A84FF"),
    "briefcase":       Color(hex: "#00C7BE"),
    "fitness":         Color(hex: "#FF453A"),
    "barbell":         Color(hex: "#FF9F0A"),
    "library":         Color(hex: "#BF5AF2"),
    "code-slash":      Color(hex: "#32ADE6"),
    "laptop":          Color(hex: "#5E5CE6"),
    "moon":            Color(hex: "#AF52DE"),
    "sunny":           Color(hex: "#FFD60A"),
    "cafe":            Color(hex: "#8D6E63"),
    "leaf":            Color(hex: "#30D158"),
    "musical-notes":   Color(hex: "#FF375F"),
    "pencil":          Color(hex: "#FFCC00"),
    "brush":           Color(hex: "#FF2D55"),
    "calculator":      Color(hex: "#30B0C7"),
    "game-controller": Color(hex: "#5856D6"),
    "flash":           Color(hex: "#FF9500"),
]

let CURATED_ICONS: [String] = [
    "book", "briefcase", "fitness", "barbell", "library", "code-slash",
    "laptop", "moon", "sunny", "cafe", "leaf", "musical-notes",
    "pencil", "brush", "calculator", "game-controller",
]

func getIconColor(_ iconName: String) -> Color {
    ICON_COLORS[iconName] ?? Color(hex: "#FF453A")
}

func sfSymbol(for iconName: String) -> String {
    ICON_SF_SYMBOLS[iconName] ?? "star.fill"
}

func getIconColorHex(_ iconName: String) -> String {
    getIconColor(iconName).toHex()
}

// MARK: - UI Extensions

extension View {
    func glassBackground<S: Shape>(in shape: S) -> some View {
        self.modifier(GlassBackgroundModifier(shape: shape))
    }
    
    func headerGradientBlur() -> some View {
        self.background {
            ZStack(alignment: .top) {
                // Base material that covers the safe area and the view itself
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea(edges: .top)
            }
            .mask {
                VStack(spacing: 0) {
                    // Solid black for the entire area of the view
                    Color.black
                    
                    // Gradient only for the bottom edge to fade out smoothly
                    LinearGradient(
                        colors: [.black, .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 30)
                }
            }
        }
    }
}

private struct GlassBackgroundModifier<S: Shape>: ViewModifier {
    let shape: S
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content.glassEffect(.regular.interactive(), in: shape)
        } else {
            content.background(.ultraThinMaterial, in: shape)
        }
    }
}
