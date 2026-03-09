import SwiftUI

/// Two-column summary card: Total Sessions (left) + Total Focus (right)
struct StatsSummaryCard: View {
    let summary: StatsSummary

    var body: some View {
        GlassCard(cornerRadius: 20) {
            HStack(spacing: 0) {

                // ── Total Sessions ──
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.white.opacity(0.6))

                    Text("\(summary.totalSessions)")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Total Sessions")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)

                // Divider
                Rectangle()
                    .fill(.white.opacity(0.1))
                    .frame(width: 1, height: 60)

                // ── Total Focus ──
                VStack(spacing: 8) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.white.opacity(0.6))

                    formattedDuration(summary.totalMinutes)

                    Text("Total Focus")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 12)
        }
    }

    // Renders e.g. "2h 35m" with big number + small unit
    @ViewBuilder
    private func formattedDuration(_ minutes: Int) -> some View {
        if minutes >= 60 {
            let h = minutes / 60
            let m = minutes % 60
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(h)")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("h")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                if m > 0 {
                    Text("\(m)")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("m")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        } else {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(minutes)")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("m")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
    }
}
