import SwiftUI
import Charts

/// Card with Today / This Week trends + stacked weekly bar chart + daily avg
struct FocusTrendCard: View {
    let todayTrend: TrendDelta
    let weekTrend: TrendDelta
    let weeklyData: [ChartDataPoint]
    let dailyAverage: Int
    let period: StatsPeriod

    var body: some View {
        GlassCard(cornerRadius: 20) {
            VStack(alignment: .leading, spacing: 20) {

                // ── Trend header row ──
                HStack(spacing: 0) {
                    trendColumn(
                        title: "Today's Focus",
                        minutes: todayTrend.minutes,
                        delta: todayTrend.deltaPercent
                    )

                    Rectangle()
                        .fill(.white.opacity(0.1))
                        .frame(width: 1, height: 50)

                    trendColumn(
                        title: "This Week",
                        minutes: weekTrend.minutes,
                        delta: weekTrend.deltaPercent
                    )
                }

                // ── Chart ──
                VStack(alignment: .leading, spacing: 8) {
                    Text("Focus Trend")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))

                    StatsChartView(data: weeklyData, period: period)

                    // Daily Average
                    HStack {
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(.white.opacity(0.4))
                            Text("Daily Avg: \(formattedShort(dailyAverage))")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                    }
                }
            }
            .padding(16)
        }
    }

    // MARK: – Sub-views

    private func trendColumn(title: String, minutes: Int, delta: Double) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))

            Text(formattedShort(minutes))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            if delta != 0 {
                HStack(spacing: 2) {
                    Image(systemName: delta > 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 9, weight: .bold))
                    Text(String(format: "%.0f%%", abs(delta)))
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(delta > 0 ? Color(hex: "#30D158") : Color(hex: "#FF453A"))
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func formattedShort(_ minutes: Int) -> String {
        if minutes >= 60 {
            let h = minutes / 60
            let m = minutes % 60
            return m > 0 ? "\(h)h \(m)m" : "\(h)h"
        }
        return "\(minutes)m"
    }
}
