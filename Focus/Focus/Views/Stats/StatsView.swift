import SwiftUI

struct StatsView: View {
    @Environment(FocusHistoryStore.self) private var historyStore
    @State private var viewModel = StatsViewModel()
    @State private var scrollOffset: CGFloat = 0

    private var isScrolled: Bool { scrollOffset < -5 }

    var body: some View {
        ZStack(alignment: .top) {
            Color(hex: "#111116").ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                ZStack(alignment: .top) {
                    // Tracking dello scroll passivo
                    GeometryReader { proxy in
                        let minY = proxy.frame(in: .named("stats_scroll")).minY
                        Color.clear.onAppear { scrollOffset = minY }
                            .onChange(of: minY) { _, newValue in
                                scrollOffset = newValue
                            }
                    }
                    .frame(height: 0)

                    VStack(spacing: 20) {
                        // Header spacer for iOS 26+ (safeAreaBar handles it)
                        // For < iOS 26 we need manual padding
                        adaptiveHeaderPadding()

                        // ── Period picker ─────────────────────────────────────
                        periodPicker

                        // ── Date navigation ──────────────────────────────────
                        dateNavigation

                        // ── Summary card (Sessions + Total Focus) ────────────
                        if let summary = viewModel.cachedSummary {
                            StatsSummaryCard(summary: summary)
                        }

                        // ── Mode Breakdown grid ──────────────────────────────
                        ModeBreakdownView(items: viewModel.cachedModeBreakdown)

                        // ── Focus Trend card ─────────────────────────────────
                        FocusTrendCard(
                            todayTrend:   viewModel.cachedTodayTrend ?? TrendDelta(minutes: 0, deltaPercent: 0),
                            weekTrend:    viewModel.cachedWeekTrend ?? TrendDelta(minutes: 0, deltaPercent: 0),
                            weeklyData:   viewModel.cachedWeeklyStackedData,
                            dailyAverage: viewModel.cachedDailyAverage,
                            period:       viewModel.selectedPeriod
                        )

                        // ── Full chart card ──────────────────────────────────
                        GlassCard(cornerRadius: 20) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Focus Time")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.6))
                                    .padding(.horizontal, 12)
                                    .padding(.top, 14)

                                StatsChartView(
                                    data: viewModel.cachedChartData,
                                    period: viewModel.selectedPeriod
                                )
                                .padding(.horizontal, 8)
                                .padding(.bottom, 14)
                            }
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
                        .padding(.bottom, 32)
                    }
                    .padding(.horizontal, 20)
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

            // Header (Solo per versioni < iOS 26 come overlay)
            if #unavailable(iOS 26) {
                VStack(spacing: 0) {
                    statsHeader
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
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
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
                .padding(.top, 60)
        }
    }

    // MARK: – Sub-views

    private var statsHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Summary")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(viewModel.headerSubtitle)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func adaptiveHeaderPadding() -> some View {
        if #available(iOS 26, *) {
            Color.clear.frame(height: 20)
        } else {
            Color.clear.frame(height: 140) // Manual space for overlay
        }
    }

    // MARK: – Period picker

    private var periodPicker: some View {
        HStack(spacing: 6) {
            ForEach(StatsPeriod.allCases) { period in
                Button {
                    withAnimation(.spring(duration: 0.3)) {
                        viewModel.selectedPeriod = period
                        viewModel.referenceDate  = Date()
                    }
                } label: {
                    Text(period.label)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(viewModel.selectedPeriod == period ? .white : .white.opacity(0.5))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background {
                            if viewModel.selectedPeriod == period {
                                Capsule()
                                    .fill(.white.opacity(0.15))
                            }
                        }
                }
            }
        }
        .glassBackground(in: Capsule())
    }

    // MARK: – Date navigation

    private var dateNavigation: some View {
        HStack {
            Button {
                withAnimation(.spring(duration: 0.3)) { viewModel.goBack() }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 36, height: 36)
                    .glassBackground(in: Circle())
            }

            Spacer()

            Text(viewModel.periodTitle)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .transition(.opacity)

            Spacer()

            Button {
                withAnimation(.spring(duration: 0.3)) { viewModel.goForward() }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(viewModel.canGoForward ? .white.opacity(0.7) : .white.opacity(0.2))
                    .frame(width: 36, height: 36)
                    .glassBackground(in: Circle())
            }
            .disabled(!viewModel.canGoForward)
        }
    }
}

// MARK: – Scroll Edge Effect (iOS 26+ / iOS 18 fallback)

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
