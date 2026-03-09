import Foundation
import Observation

// MARK: – Period

enum StatsPeriod: String, CaseIterable, Identifiable {
    case day, week, month, year
    var id: String { rawValue }

    var label: String {
        switch self {
        case .day:   "Day"
        case .week:  "Week"
        case .month: "Month"
        case .year:  "Year"
        }
    }
    
    var shortLabel: String {
        switch self {
        case .day:   "D"
        case .week:  "W"
        case .month: "M"
        case .year:  "Y"
        }
    }
}

// MARK: – Chart data point

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let label: String
    let minutes: Int
    let colorHex: String
    let modeName: String
}

// MARK: – Summary

struct StatsSummary {
    let totalSessions: Int
    let totalMinutes: Int
    let longestSessionMinutes: Int
    let averageDailyMinutes: Double
    let topModeName: String
    let topModeIcon: String
    let topModeColor: String
}

// MARK: – Mode breakdown item

struct ModeBreakdownItem: Identifiable {
    let id = UUID()
    let modeId: String
    let modeName: String
    let colorHex: String
    let minutes: Int
    let percentage: Double
}

// MARK: – Trend delta

struct TrendDelta {
    let minutes: Int
    let deltaPercent: Double   // positive = improvement, negative = regression
}

// MARK: – ViewModel

@Observable
final class StatsViewModel {

    var selectedPeriod: StatsPeriod = .day
    var referenceDate: Date = Date()
    var selectedModeId: String? = nil
    var isRefreshing = false

    // MARK: – Cached Data

    private(set) var cachedSummary: StatsSummary?
    private(set) var cachedModeBreakdown: [ModeBreakdownItem] = []
    private(set) var cachedChartData: [ChartDataPoint] = []
    private(set) var cachedDailyAverage: Int = 0

    private let calendar = Calendar.current

    /// Updates all cached data based on the provided sessions.
    /// Performs calculations on a background thread to keep UI responsive.
    func refresh(with sessions: [FocusSession]) {
        isRefreshing = true
        
        // Capture current state to avoid race conditions during async work
        let period = selectedPeriod
        let date = referenceDate
        let modeId = selectedModeId
        
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }
            
            let summary = self.calculateSummary(from: sessions, period: period, date: date, modeId: modeId)
            let breakdown = self.calculateModeBreakdown(from: sessions, period: period, date: date)
            let chart = self.calculateChartData(from: sessions, period: period, date: date, modeId: modeId)
            
            await MainActor.run {
                self.cachedSummary = summary
                self.cachedModeBreakdown = breakdown
                self.cachedChartData = chart
                self.isRefreshing = false
            }
        }
    }

    // MARK: – Navigation

    @MainActor
    func goBack() {
        referenceDate = shift(by: -1)
    }

    @MainActor
    func goForward() {
        let next = shift(by: 1)
        if next <= Date() { referenceDate = next }
    }

    var canGoForward: Bool {
        shift(by: 1) <= Date()
    }

    var periodTitle: String {
        let fmt = DateFormatter()
        switch selectedPeriod {
        case .day:
            fmt.dateFormat = "EEEE, MMM d"
            return fmt.string(from: referenceDate)
        case .week:
            guard let interval = calendar.dateInterval(of: .weekOfYear, for: referenceDate) else { return "" }
            fmt.dateFormat = "d MMM"
            let start = fmt.string(from: interval.start)
            let end   = fmt.string(from: interval.end.addingTimeInterval(-1))
            return "\(start) – \(end)"
        case .month:
            fmt.dateFormat = "MMMM yyyy"
            return fmt.string(from: referenceDate)
        case .year:
            fmt.dateFormat = "yyyy"
            return fmt.string(from: referenceDate)
        }
    }

    // MARK: – Private Calculation Helpers (Thread Safe)

    private func calculateChartData(from sessions: [FocusSession], period: StatsPeriod, date: Date, modeId: String?) -> [ChartDataPoint] {
        let filtered = internalFilteredSessions(from: sessions, period: period, date: date, modeId: modeId)

        switch period {
        case .day:
            return groupByHour(filtered)
        case .week:
            return groupByWeekday(filtered, date: date)
        case .month:
            return groupByDayOfMonth(filtered, date: date)
        case .year:
            return groupByMonth(filtered)
        }
    }

    private func calculateSummary(from sessions: [FocusSession], period: StatsPeriod, date: Date, modeId: String?) -> StatsSummary {
        let filtered = internalFilteredSessions(from: sessions, period: period, date: date, modeId: modeId)
        let total    = filtered.reduce(0) { $0 + $1.duration }
        let longest  = filtered.map { $0.duration }.max() ?? 0
        let days     = internalDaysInPeriod(period: period, date: date)

        var modeCounts: [String: (count: Int, color: String)] = [:]
        for s in filtered {
            let entry = modeCounts[s.modeTitle] ?? (0, s.color)
            modeCounts[s.modeTitle] = (entry.count + 1, s.color)
        }
        let top = modeCounts.max(by: { $0.value.count < $1.value.count })

        return StatsSummary(
            totalSessions:       filtered.count,
            totalMinutes:        total,
            longestSessionMinutes: longest,
            averageDailyMinutes: days > 0 ? Double(total) / Double(days) : 0,
            topModeName:         top?.key ?? "–",
            topModeIcon:         "",
            topModeColor:        top?.value.color ?? "#FFFFFF"
        )
    }

    private func calculateModeBreakdown(from sessions: [FocusSession], period: StatsPeriod, date: Date) -> [ModeBreakdownItem] {
        guard let interval = internalDateInterval(period: period, date: date) else { return [] }
        let periodSessions = sessions.filter { interval.contains($0.startDate) }
        
        let totalMins = periodSessions.reduce(0) { $0 + $1.duration }
        guard totalMins > 0 else { return [] }

        var buckets: [String: (id: String, color: String, minutes: Int)] = [:]
        for s in periodSessions {
            let entry = buckets[s.modeTitle] ?? (s.modeTitle, s.color, 0)
            buckets[s.modeTitle] = (entry.id, entry.color, entry.minutes + s.duration)
        }

        return buckets
            .map { ModeBreakdownItem(
                modeId: $0.value.id,
                modeName: $0.key,
                colorHex: $0.value.color,
                minutes: $0.value.minutes,
                percentage: Double($0.value.minutes) / Double(totalMins) * 100
            )}
            .sorted { $0.minutes > $1.minutes }
    }

    private func shift(by direction: Int) -> Date {
        let component: Calendar.Component
        switch selectedPeriod {
        case .day:   component = .day
        case .week:  component = .weekOfYear
        case .month: component = .month
        case .year:  component = .year
        }
        return calendar.date(byAdding: component, value: direction, to: referenceDate) ?? referenceDate
    }

    private func internalFilteredSessions(from sessions: [FocusSession], period: StatsPeriod, date: Date, modeId: String?) -> [FocusSession] {
        guard let interval = internalDateInterval(period: period, date: date) else { return [] }
        var result = sessions.filter { interval.contains($0.startDate) }
        if let modeId = modeId {
            result = result.filter { $0.modeTitle == modeId }
        }
        return result
    }

    private func internalDateInterval(period: StatsPeriod, date: Date) -> DateInterval? {
        let component: Calendar.Component
        switch period {
        case .day:   component = .day
        case .week:  component = .weekOfYear
        case .month: component = .month
        case .year:  component = .year
        }
        return calendar.dateInterval(of: component, for: date)
    }

    private func internalDaysInPeriod(period: StatsPeriod, date: Date) -> Int {
        guard let interval = internalDateInterval(period: period, date: date) else { return 1 }
        return max(1, calendar.dateComponents([.day], from: interval.start, to: interval.end).day ?? 1)
    }

    // ── Groupings ────────────────────────────────────────────────

    private func groupByHour(_ sessions: [FocusSession]) -> [ChartDataPoint] {
        var buckets: [Int: [(String, Int, String)]] = [:]
        for s in sessions {
            let hour = calendar.component(.hour, from: s.startDate)
            buckets[hour, default: []].append((s.modeTitle, s.duration, s.color))
        }
        var result: [ChartDataPoint] = []
        for hour in 0..<24 {
            let label: String
            if hour == 0 { label = "12am" }
            else if hour == 7 { label = "7am" }
            else if hour == 13 { label = "1pm" }
            else if hour == 19 { label = "7pm" }
            else { label = "" }

            if let entries = buckets[hour] {
                for e in entries {
                    result.append(ChartDataPoint(label: label, minutes: e.1, colorHex: e.2, modeName: e.0))
                }
            } else if !label.isEmpty {
                result.append(ChartDataPoint(label: label, minutes: 0, colorHex: "#FFFFFF", modeName: ""))
            }
        }
        return result
    }

    private func groupByWeekday(_ sessions: [FocusSession], date: Date) -> [ChartDataPoint] {
        let symbols = calendar.shortWeekdaySymbols
        let first   = calendar.firstWeekday
        let ordered = Array(first...7) + Array(1..<first)

        var buckets: [Int: [(String, Int, String)]] = [:]
        for s in sessions {
            let wd = calendar.component(.weekday, from: s.startDate)
            buckets[wd, default: []].append((s.modeTitle, s.duration, s.color))
        }

        var result: [ChartDataPoint] = []
        for wd in ordered {
            let label = symbols[wd - 1]
            if let entries = buckets[wd] {
                for e in entries {
                    result.append(ChartDataPoint(label: label, minutes: e.1, colorHex: e.2, modeName: e.0))
                }
            }
        }
        return result
    }

    private func groupByDayOfMonth(_ sessions: [FocusSession], date: Date) -> [ChartDataPoint] {
        var buckets: [Int: [(String, Int, String)]] = [:]
        for s in sessions {
            let day = calendar.component(.day, from: s.startDate)
            buckets[day, default: []].append((s.modeTitle, s.duration, s.color))
        }
        let daysCount = calendar.range(of: .day, in: .month, for: date)?.count ?? 30
        var result: [ChartDataPoint] = []
        for d in 1...daysCount {
            if let entries = buckets[d] {
                for e in entries {
                    result.append(ChartDataPoint(label: "\(d)", minutes: e.1, colorHex: e.2, modeName: e.0))
                }
            }
        }
        return result
    }

    private func groupByMonth(_ sessions: [FocusSession]) -> [ChartDataPoint] {
        let symbols = calendar.shortMonthSymbols
        var buckets: [Int: [(String, Int, String)]] = [:]
        for s in sessions {
            let m = calendar.component(.month, from: s.startDate)
            buckets[m, default: []].append((s.modeTitle, s.duration, s.color))
        }
        var result: [ChartDataPoint] = []
        for m in 1...12 {
            if let entries = buckets[m] {
                for e in entries {
                    result.append(ChartDataPoint(label: symbols[m - 1], minutes: e.1, colorHex: e.2, modeName: e.0))
                }
            }
        }
        return result
    }
}
