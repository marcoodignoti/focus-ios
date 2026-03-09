import SwiftUI

/// 2×2 grid showing mode breakdown with color bar, name, duration, and %
struct ModeBreakdownView: View {
    let items: [ModeBreakdownItem]
    @State private var showAll = false

    private var displayedItems: [ModeBreakdownItem] {
        if showAll || items.count <= 4 {
            return items
        }
        return Array(items.prefix(4))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Mode Breakdown")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))

                Spacer()

                if items.count > 4 {
                    Button {
                        withAnimation(.spring(duration: 0.3)) { showAll.toggle() }
                    } label: {
                        Text(showAll ? "Show Less" : "Show All")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
            }

            if items.isEmpty {
                Text("No sessions yet")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.3))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    ForEach(displayedItems) { item in
                        modeCell(item)
                    }
                }
            }
        }
    }

    private func modeCell(_ item: ModeBreakdownItem) -> some View {
        GlassCard(cornerRadius: 16) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(Color(hex: item.colorHex))
                        .frame(width: 4, height: 24)

                    Text(item.modeName)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }

                HStack(alignment: .firstTextBaseline) {
                    Text(formattedDuration(item.minutes))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Spacer()

                    Text(String(format: "%.0f%%", item.percentage))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .padding(14)
        }
    }

    private func formattedDuration(_ minutes: Int) -> String {
        if minutes >= 60 {
            let h = minutes / 60
            let m = minutes % 60
            return m > 0 ? "\(h)h \(m)m" : "\(h)h"
        }
        return "\(minutes)m"
    }
}
