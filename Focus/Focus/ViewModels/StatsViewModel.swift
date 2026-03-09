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
@MainActor
final class StatsViewModel {

    var selectedPeriod: StatsPeriod = .day // Default to Day for the detailed view
    var referenceDate: Date = Date()
    var selectedModeId: String? = nil

    // MARK: – Cached Data

    private(set) var cachedSummary: StatsSummary?
    private(set) var cachedModeBreakdown: [ModeBreakdownItem] = []
    private(set) var cachedTodayTrend: TrendDelta?
    private(set) var cachedWeekTrend: TrendDelta?
    private(set) var cachedWeeklyStackedData: [ChartDataPoint] = []
    private(set) var cachedChartData: [ChartDataPoint] = []
    private(set) var cachedDailyAverage: Int = 0

    private let calendar = Calendar.current

    /// Updates all cached data based on the provided sessions.
    func refresh(with sessions: [FocusSession]) {
        self.cachedSummary = summary(from: sessions)
        self.cachedModeBreakdown = modeBreakdown(from: sessions)
        self.cachedTodayTrend = todayTrend(from: sessions)
        self.cachedWeekTrend = weekTrend(from: sessions)
        self.cachedWeeklyStackedData = weeklyStackedData(from: sessions)
        self.cachedChartData = chartData(from: sessions)
        self.cachedDailyAverage = weekDailyAverage(from: sessions)
    }

    // MARK: – Navigation

    func goBack() {
        referenceDate = shift(by: -1)
    }

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

    var headerSubtitle: String {
        let months = ["Jan","Feb","Mar","Apr","May","Jun",
                      "Jul","Aug","Sep","Oct","Nov","Dec"]
        let isToday = calendar.isDateInToday(referenceDate)
        let m = calendar.component(.month, from: referenceDate) - 1
        let d = calendar.component(.day,   from: referenceDate)
        return "\(months[m]) \(d)\(isToday ? ", Today" : "")"
    }

    // MARK: – Chart Data

    func chartData(from sessions: [FocusSession]) -> [ChartDataPoint] {
        let filtered = filteredSessions(from: sessions)

        switch selectedPeriod {
        case .day:
            return groupByHour(filtered)
        case .week:
            return groupByWeekday(filtered)
        case .month:
            return groupByDayOfMonth(filtered)
        case .year:
            return groupByMonth(filtered)
        }
    }

    // MARK: – Summary

    func summary(from sessions: [FocusSession]) -> StatsSummary {
        let filtered = filteredSessions(from: sessions)
        let total    = filtered.reduce(0) { $0 + $1.duration }
        let longest  = filtered.map { $0.duration }.max() ?? 0
        let days     = daysInPeriod()

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

    // MARK: – Mode Breakdown

    func modeBreakdown(from sessions: [FocusSession]) -> [ModeBreakdownItem] {
        guard let interval = dateInterval() else { return [] }
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

    // MARK: – Trends

    func todayTrend(from sessions: [FocusSession]) -> TrendDelta {
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let todayMins = sessions
            .filter { calendar.isDate($0.startDate, inSameDayAs: today) }
            .reduce(0) { $0 + $1.duration }
        let yesterdayMins = sessions
            .filter { calendar.isDate($0.startDate, inSameDayAs: yesterday) }
            .reduce(0) { $0 + $1.duration }

        let delta: Double = yesterdayMins > 0
            ? (Double(todayMins - yesterdayMins) / Double(yesterdayMins)) * 100
            : (todayMins > 0 ? 100 : 0)

        return TrendDelta(minutes: todayMins, deltaPercent: delta)
    }

    func weekTrend(from sessions: [FocusSession]) -> TrendDelta {
        guard let thisWeek = calendar.dateInterval(of: .weekOfYear, for: Date()) else {
            return TrendDelta(minutes: 0, deltaPercent: 0)
        }
        let prevWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: thisWeek.start)!
        guard let prevWeek = calendar.dateInterval(of: .weekOfYear, for: prevWeekStart) else {
            return TrendDelta(minutes: 0, deltaPercent: 0)
        }

        let thisMins = sessions
            .filter { thisWeek.contains($0.startDate) }
            .reduce(0) { $0 + $1.duration }
        let prevMins = sessions
            .filter { prevWeek.contains($0.startDate) }
            .reduce(0) { $0 + $1.duration }

        let delta: Double = prevMins > 0
            ? (Double(thisMins - prevMins) / Double(prevMins)) * 100
            : (thisMins > 0 ? 100 : 0)

        return TrendDelta(minutes: thisMins, deltaPercent: delta)
    }

    func weekDailyAverage(from sessions: [FocusSession]) -> Int {
        guard let thisWeek = calendar.dateInterval(of: .weekOfYear, for: Date()) else { return 0 }
        let totalMins = sessions
            .filter { thisWeek.contains($0.startDate) }
            .reduce(0) { $0 + $1.duration }

        let elapsed = max(1, calendar.dateComponents([.day], from: thisWeek.start, to: min(Date(), thisWeek.end)).day ?? 1)
        return totalMins / elapsed
    }

    func weeklyStackedData(from sessions: [FocusSession]) -> [ChartDataPoint] {
        guard let thisWeek = calendar.dateInterval(of: .weekOfYear, for: referenceDate) else { return [] }
        let filtered = sessions.filter { thisWeek.contains($0.startDate) }
        return groupByWeekday(filtered)
    }

    var currentWeekdayIndex: Int {
        calendar.component(.weekday, from: Date())
    }

    // MARK: – Private helpers

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

    private func filteredSessions(from sessions: [FocusSession]) -> [FocusSession] {
        guard let interval = dateInterval() else { return [] }
        var result = sessions.filter { interval.contains($0.startDate) }
        
        if let modeId = selectedModeId {
            result = result.filter { $0.modeTitle == modeId }
        }
        
        return result
    }

    private func dateInterval() -> DateInterval? {
        let component: Calendar.Component
        switch selectedPeriod {
        case .day:   component = .day
        case .week:  component = .weekOfYear
        case .month: component = .month
        case .year:  component = .year
        }
        return calendar.dateInterval(of: component, for: referenceDate)
    }

    private func daysInPeriod() -> Int {
        guard let interval = dateInterval() else { return 1 }
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

    private func groupByWeekday(_ sessions: [FocusSession]) -> [ChartDataPoint] {
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

    private func groupByDayOfMonth(_ sessions: [FocusSession]) -> [ChartDataPoint] {
        var buckets: [Int: [(String, Int, String)]] = [:]
        for s in sessions {
            let day = calendar.component(.day, from: s.startDate)
            buckets[day, default: []].append((s.modeTitle, s.duration, s.color))
        }
        let daysCount = calendar.range(of: .day, in: .month, for: referenceDate)?.count ?? 30
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
