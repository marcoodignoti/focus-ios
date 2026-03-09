import SwiftUI

struct StatsView: View {
    @Environment(FocusHistoryStore.self) private var historyStore
    @Environment(FocusModesStore.self) private var modesStore
    @Environment(AchievementStore.self) private var achievementStore
    @State private var viewModel = StatsViewModel()
    @State private var scrollOffset: CGFloat = 0
    @State private var currentWeekOffset = 0
    @State private var showAchievements = false

    private var isScrolled: Bool { scrollOffset < -5 }

    var body: some View {
        @Bindable var bindableAchievement = achievementStore
        
        ZStack(alignment: .top) {
            Color(hex: "#111116").ignoresSafeArea()
            
            LinearGradient(
                colors: [Color(hex: "#2A2A35"), Color(hex: "#111116")],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                ZStack(alignment: .top) {
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
                                    HStack {
                                        // DEBUG BUTTON
                                        Button {
                                            if let a = achievementStore.achievements.first {
                                                achievementStore.newlyUnlockedAchievement = a
                                            }
                                        } label: {
                                            Image(systemName: "sparkles")
                                                .foregroundStyle(.orange.opacity(0.4))
                                        }
                                        
                                        Spacer()
                                        streakIndicator
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.top, 16)

                                    Text(viewModel.periodTitle)
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.5))
                                    
                                    formattedTotalDuration(viewModel.cachedSummary?.totalMinutes ?? 0)
                                    
                                    Text("total focus time")
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.3))
                                }

                                periodSelector

                                // Chart
                                VStack(alignment: .leading, spacing: 12) {
                                    StatsChartView(
                                        data: viewModel.cachedChartData,
                                        period: viewModel.selectedPeriod
                                    )
                                    .frame(height: 160)
                                }

                                modeFiltersRow

                                // Bottom summary
                                if let summary = viewModel.cachedSummary {
                                    HStack(spacing: 12) {
                                        summaryBox(value: "\(summary.totalSessions)", label: "focus sessions")
                                        summaryBox(value: formattedHourDuration(summary.longestSessionMinutes), label: "longest session")
                                    }
                                }
                                
                                // ── Achievements Section ──
                                achievementsPreview
                                    .padding(.bottom, 24)
                            }
                            .padding(.horizontal, 16)
                        }

                        // Swipe-down hint
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
                refreshAll()
            }
            .onChange(of: historyStore.sessions) { _, _ in refreshAll() }
            .onChange(of: viewModel.selectedPeriod) { _, _ in refreshAll() }
            .onChange(of: viewModel.referenceDate) { _, _ in refreshAll() }
            .onChange(of: viewModel.selectedModeId) { _, _ in refreshAll() }
            
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
            }
        }
        .applyNativeStatsHeader(edge: .top) {
            statsHeader
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
                .padding(.top, 60)
        }
        .sheet(isPresented: $showAchievements) {
            AchievementsListView()
        }
        .overlay {
            if let ach = bindableAchievement.newlyUnlockedAchievement {
                AchievementUnlockOverlay(achievement: ach) {
                    achievementStore.newlyUnlockedAchievement = nil
                }
                .transition(.opacity)
                .zIndex(100)
            }
        }
    }

    private func refreshAll() {
        viewModel.refresh(with: historyStore.sessions)
        achievementStore.updateProgress(sessions: historyStore.sessions)
    }

    // MARK: – Sub-views

    private var statsHeader: some View {
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
        .frame(height: 70)
    }

    private var streakIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .foregroundStyle(.orange)
            Text("\(achievementStore.currentStreak)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.white.opacity(0.1))
        .clipShape(Capsule())
    }

    private var achievementsPreview: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Achievements")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                Button {
                    showAchievements = true
                } label: {
                    Text("See All")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.orange)
                }
            }
            
            HStack(spacing: 20) {
                ForEach(achievementStore.achievements.filter { $0.isUnlocked }.prefix(3)) { ach in
                    BadgeView(achievement: ach)
                        .scaleEffect(0.7)
                        .frame(width: 70)
                }
                
                if achievementStore.achievements.filter({ $0.isUnlocked }).isEmpty {
                    Text("Complete sessions to unlock badges!")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.3))
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    private func formattedTotalDuration(_ minutes: Int) -> some View {
        let h = minutes / 60
        let m = minutes % 60
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text("\(h)").font(.system(size: 64, weight: .bold, design: .rounded)).foregroundStyle(.white)
            Text("h").font(.system(size: 32, weight: .bold, design: .rounded)).foregroundStyle(.white.opacity(0.5))
            Text("\(m)").font(.system(size: 64, weight: .bold, design: .rounded)).foregroundStyle(.white).padding(.leading, 8)
            Text("m").font(.system(size: 32, weight: .bold, design: .rounded)).foregroundStyle(.white.opacity(0.5))
        }
    }

    private func formattedHourDuration(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        return h > 0 ? (m > 0 ? "\(h)h \(m)m" : "\(h)h") : "\(m)m"
    }

    private var periodSelector: some View {
        HStack(spacing: 4) {
            ForEach(StatsPeriod.allCases) { period in
                Button { withAnimation(.spring(duration: 0.3)) { viewModel.selectedPeriod = period } } label: {
                    Text(period.shortLabel)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(viewModel.selectedPeriod == period ? .white : .white.opacity(0.3))
                        .frame(maxWidth: .infinity).frame(height: 44)
                        .background { if viewModel.selectedPeriod == period { RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.1)) } }
                }
            }
        }
        .padding(4).background(.black.opacity(0.2)).clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var modeFiltersRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                filterPill(id: nil, title: "All", icon: "square.grid.2x2.fill")
                ForEach(modesStore.modes) { mode in
                    filterPill(id: mode.name, title: mode.name, icon: sfSymbol(for: mode.icon))
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private func filterPill(id: String?, title: String, icon: String) -> some View {
        Button { withAnimation(.spring(duration: 0.3)) { viewModel.selectedModeId = id } } label: {
            ZStack {
                Circle().fill(viewModel.selectedModeId == id ? .white : .white.opacity(0.1)).frame(width: 44, height: 44)
                Image(systemName: icon).font(.system(size: 18, weight: .semibold)).foregroundStyle(viewModel.selectedModeId == id ? .black : .white.opacity(0.6))
            }
        }
    }

    private func summaryBox(value: String, label: String) -> some View {
        VStack(spacing: 8) {
            Text(value).font(.system(size: 28, weight: .bold, design: .rounded)).foregroundStyle(.white)
            Text(label).font(.system(size: 12, weight: .medium, design: .rounded)).foregroundStyle(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity).padding(.vertical, 20).background(.white.opacity(0.05)).clipShape(RoundedRectangle(cornerRadius: 24))
    }

    @ViewBuilder
    private func adaptiveHeaderPadding() -> some View {
        if #available(iOS 26, *) {
            Color.clear.frame(height: 10)
        } else {
            Color.clear.frame(height: 160)
        }
    }
    
    private func weekDays(for offset: Int) -> [Date] {
        let cal = Calendar(identifier: .iso8601)
        let monday = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        let target = cal.date(byAdding: .weekOfYear, value: offset, to: monday)!
        return (0..<7).map { cal.date(byAdding: .day, value: $0, to: target)! }
    }
}

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
                Text(weekday).font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(isSelected ? .white : .white.opacity(0.3))
                ZStack {
                    Circle().fill(isSelected ? .white.opacity(0.2) : .clear).frame(width: 36, height: 36).overlay(Circle().stroke(.white.opacity(0.1), lineWidth: 1))
                    Image(systemName: isToday ? "star.fill" : "plus").font(.system(size: 12, weight: .bold)).foregroundStyle(isSelected ? .white : .white.opacity(0.4)).italic().offset(x: 2, y: -2)
                }
            }
            .frame(width: 44).opacity(isSelected || isToday ? 1.0 : 0.6)
        }
    }
}

// MARK: – Extensions

extension View {
    @ViewBuilder
    func applyNativeStatsHeader<Content: View>(edge: VerticalEdge, @ViewBuilder content: () -> Content) -> some View {
        if #available(iOS 26, *) {
            self.safeAreaBar(edge: edge, content: content)
        } else {
            self
        }
    }

    @ViewBuilder
    func applyScrollEdgeFallback() -> some View {
        if #available(iOS 26.0, *) {
            self.scrollEdgeEffectStyle(.soft, for: .top)
        } else {
            self.overlay(
                LinearGradient(
                    colors: [Color(hex: "#111116"), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 20)
                .allowsHitTesting(false),
                alignment: .top
            )
        }
    }
}
