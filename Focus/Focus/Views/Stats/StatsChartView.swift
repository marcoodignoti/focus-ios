import SwiftUI
import Charts

/// Detailed bar chart with specific time labels and average line
struct StatsChartView: View {
    let data: [ChartDataPoint]
    let period: StatsPeriod

    private var averageMinutes: Double {
        let values = data.map { Double($0.minutes) }
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    var body: some View {
        Chart {
            ForEach(data) { point in
                BarMark(
                    x: .value("Period", point.label),
                    y: .value("Minutes", point.minutes)
                )
                .foregroundStyle(Color(hex: point.colorHex))
                .cornerRadius(4)
            }

            if period == .day && averageMinutes > 0 {
                RuleMark(y: .value("Average", averageMinutes))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(.white.opacity(0.3))
                    .annotation(position: .top, alignment: .leading) {
                        Text("Avg: \(Int(averageMinutes))m")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.3))
                    }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                if let label = value.as(String.self), !label.isEmpty {
                    AxisValueLabel()
                        .foregroundStyle(.white.opacity(0.5))
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                }
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(.white.opacity(0.1))
                
                if let min = value.as(Int.self), min > 0 {
                    AxisValueLabel {
                        Text("\(min)m")
                            .font(.system(size: 9, design: .rounded))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                }
            }
        }
        .animation(.spring(duration: 0.4), value: data.map(\.id))
    }
}
