import SwiftUI
import Charts

/// Stacked bar chart coloured by focus mode
struct StatsChartView: View {
    let data: [ChartDataPoint]
    let period: StatsPeriod

    var body: some View {
        Chart(data) { point in
            BarMark(
                x: .value("Period", point.label),
                y: .value("Minutes", point.minutes)
            )
            .foregroundStyle(Color(hex: point.colorHex))
            .cornerRadius(3)
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisValueLabel()
                    .foregroundStyle(.white.opacity(0.5))
                    .font(.system(size: xLabelSize, weight: .regular, design: .rounded))
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                    .foregroundStyle(.white.opacity(0.12))
                AxisValueLabel()
                    .foregroundStyle(.white.opacity(0.4))
                    .font(.system(size: 10, design: .rounded))
            }
        }
        .chartYAxisLabel {
            Text("min")
                .font(.system(size: 9, design: .rounded))
                .foregroundStyle(.white.opacity(0.3))
        }
        .frame(height: 200)
        .padding(.horizontal, 4)
        .animation(.spring(duration: 0.4), value: data.map(\.id))
    }

    private var xLabelSize: CGFloat {
        switch period {
        case .day:   8
        case .week:  11
        case .month: 7
        case .year:  10
        }
    }
}
