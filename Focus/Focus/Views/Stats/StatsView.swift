import SwiftUI

struct StatsView: View {
    @Environment(FocusHistoryStore.self) private var historyStore
    @Environment(FocusModesStore.self) private var modesStore
    @State private var viewModel = StatsViewModel()
    @State private var scrollOffset: CGFloat = 0
    @State private var currentWeekOffset = 0

    private var isScrolled: Bool { scrollOffset < -5 }

    private var weekdaySymbols: [String] {
        Calendar.current.veryShortWeekdaySymbols
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color(hex: "#111116").ignoresSafeArea()
            
            // Background gradient
            LinearGradient(
                colors: [Color(hex: "#2A2A35"), Color(hex: "#111116")],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                ZStack(alignment: .top) {
                    // Passive scroll tracking
                    GeometryReader { proxy in
                        let minY = proxy.frame(in: .named("stats_scroll")).minY
                        Color.clear.onAppear { scrollOffset = minY }
                            .onChange(of: minY) { _, newValue in
                                scrollOffset = newValue
                            }
                    }
                    .frame(height: 0)

                    VStack(spacing: 24) {
                        adaptiveHeaderPadding()

                        // ── Main Glass Card ──────────────────────────────────
                        GlassCard(cornerRadius: 32) {
                            VStack(spacing: 24) {
                                // Date & Total Time
                                VStack(spacing: 4) {
                                    Text(viewModel.periodTitle)
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.5))
                                    
                                    formattedTotalDuration(viewModel.cachedSummary?.totalMinutes ?? 0)
                                    
                                    Text("total focus time")
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.3))
                                }
                                .padding(.top, 24)

                                // Period Selector (D W M Y)
                                periodSelector

                                // Chart
                                VStack(alignment: .leading, spacing: 12) {
                                    if let summary = viewModel.cachedSummary {
                                        HStack {
                                            Text(formattedHourDuration(summary.longestSessionMinutes))
                                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                                .foregroundStyle(.white.opacity(0.4))
                                            Spacer()
                                        }
                                        .padding(.horizontal, 16)
                                    }

                                    StatsChartView(
                                        data: viewModel.cachedChartData,
                                        period: viewModel.selectedPeriod
                                    )
                                    .frame(height: 160)
                                }

                                // Mode Filters
                                modeFiltersRow

                                // Bottom summary (Sessions & Longest)
                                if let summary = viewModel.cachedSummary {
                                    HStack(spacing: 12) {
                                        summaryBox(
                                            value: "\(summary.totalSessions)",
                                            label: "focus sessions"
                                        )
                                        summaryBox(
                                            value: formattedHourDuration(summary.longestSessionMinutes),
                                            label: "longest session"
                                        )
                                    }
                                    .padding(.bottom, 24)
                                }
                            }
                            .padding(.horizontal, 16)
                        }

                        // ── Swipe-down hint ───────────────────────────────────
                        VStack(spacing: 8) {
                            Image(systemName: "chevron.compact.down")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundStyle(.white.opacity(0.25))

                            Text("Swipe down to go back")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.25))
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 16)
                }
            }
            .coordinateSpace(name: "stats_scroll")
            .applyScrollEdgeFallback()
            .task {
                viewModel.refresh(with: historyStore.sessions)
            }
            .onChange(of: historyStore.sessions) { _, _ in
                viewModel.refresh(with: historyStore.sessions)
            }
            .onChange(of: viewModel.selectedPeriod) { _, _ in
                viewModel.refresh(with: historyStore.sessions)
            }
            .onChange(of: viewModel.referenceDate) { _, _ in
                viewModel.refresh(with: historyStore.sessions)
            }
            .onChange(of: viewModel.selectedModeId) { _, _ in
                viewModel.refresh(with: historyStore.sessions)
            }

            // Header
            if #unavailable(iOS 26) {
                VStack(spacing: 0) {
                    statsHeader
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                        .padding(.top, 50)
                }
                .background {
                    Color.clear
                        .background(.ultraThinMaterial)
                        .opacity(isScrolled ? 1 : 0)
                        .ignoresSafeArea(edges: .top)
                }
                .animation(.easeInOut(duration: 0.2), value: isScrolled)
            }
        }
        .applyNativeStatsHeader(edge: .top) {
            statsHeader
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
                .padding(.top, 60)
        }
    }

    // MARK: – Sub-views

    private var statsHeader: some View {
        VStack(spacing: 16) {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 8) {
                    ForEach(-10...1, id: \.self) { offset in
                        let week = weekDays(for: offset)
                        HStack(spacing: 12) {
                            ForEach(week, id: \.self) { day in
                                DatePillView(
                                    day: day,
                                    isSelected: Calendar.current.isDate(day, inSameDayAs: viewModel.referenceDate),
                                    onTap: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            viewModel.referenceDate = day
                                            viewModel.selectedPeriod = .day
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 4)
                        .containerRelativeFrame(.horizontal)
                        .id(offset)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: Binding(
                get: { currentWeekOffset },
                set: { newValue in if let v = newValue { currentWeekOffset = v } }
            ))
            .frame(height: 70)
        }
    }

    @ViewBuilder
    private func formattedTotalDuration(_ minutes: Int) -> some View {
        let h = minutes / 60
        let m = minutes % 60
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text("\(h)")
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("h")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
            
            Text("\(m)")
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.leading, 8)
            Text("m")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    private func formattedHourDuration(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h > 0 {
            return m > 0 ? "\(h)h \(m)m" : "\(h)h"
        }
        return "\(m)m"
    }

    private var periodSelector: some View {
        HStack(spacing: 4) {
            ForEach(StatsPeriod.allCases) { period in
                Button {
                    withAnimation(.spring(duration: 0.3)) {
                        viewModel.selectedPeriod = period
                    }
                } label: {
                    Text(period.shortLabel)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(viewModel.selectedPeriod == period ? .white : .white.opacity(0.3))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background {
                            if viewModel.selectedPeriod == period {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.white.opacity(0.1))
                            }
                        }
                }
            }
        }
        .padding(4)
        .background(.black.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var modeFiltersRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // "All" filter
                filterPill(id: nil, title: "All", icon: "square.grid.2x2.fill")
                
                // Mode specific filters
                ForEach(modesStore.modes) { mode in
                    filterPill(id: mode.name, title: mode.name, icon: sfSymbol(for: mode.icon))
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private func filterPill(id: String?, title: String, icon: String) -> some View {
        Button {
            withAnimation(.spring(duration: 0.3)) {
                viewModel.selectedModeId = id
            }
        } label: {
            ZStack {
                if viewModel.selectedModeId == id {
                    Circle()
                        .fill(.white)
                        .frame(width: 44, height: 44)
                } else {
                    Circle()
                        .fill(.white.opacity(0.1))
                        .frame(width: 44, height: 44)
                }
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(viewModel.selectedModeId == id ? .black : .white.opacity(0.6))
            }
        }
    }

    private func summaryBox(value: String, label: String) -> some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private func adaptiveHeaderPadding() -> some View {
        if #available(iOS 26, *) {
            Color.clear.frame(height: 10)
        } else {
            Color.clear.frame(height: 160)
        }
    }
    
    private func weekDays(for offset: Int) -> [Date] {
        let cal    = Calendar(identifier: .iso8601)
        let monday = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        let target = cal.date(byAdding: .weekOfYear, value: offset, to: monday)!
        return (0..<7).map { cal.date(byAdding: .day, value: $0, to: target)! }
    }
}

// MARK: – DatePillView

private struct DatePillView: View {
    let day: Date
    let isSelected: Bool
    let onTap: () -> Void

    private var isToday: Bool { Calendar.current.isDateInToday(day) }
    private var weekday: String {
        let idx = Calendar.current.component(.weekday, from: day) - 1
        return Calendar.current.veryShortWeekdaySymbols[idx]
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Text(weekday)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.3))
                
                ZStack {
                    Circle()
                        .fill(isSelected ? .white.opacity(0.2) : .clear)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Circle()
                                .stroke(.white.opacity(0.1), lineWidth: 1)
                        )
                    
                    // Simple icon based on focus (just a placeholder style for the "star/plus" look)
                    Image(systemName: isToday ? "star.fill" : "plus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(isSelected ? .white : .white.opacity(0.4))
                        .italic()
                        .offset(x: 2, y: -2)
                }
            }
            .frame(width: 44)
            .opacity(isSelected || isToday ? 1.0 : 0.6)
        }
    }
}
