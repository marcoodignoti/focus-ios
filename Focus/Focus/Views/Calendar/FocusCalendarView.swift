import SwiftUI

private let HOUR_HEIGHT: CGFloat = 150
private let SIDE_MARGIN: CGFloat = 16

struct FocusCalendarView: View {
    @Environment(FocusHistoryStore.self) private var historyStore
    @Environment(UIStateStore.self) private var uiStore

    @State private var currentWeekOffset = 0
    @State private var showClearConfirm = false
    @State private var scrollOffset: CGFloat = 0

    // MARK: – Derived

    private var isScrolled: Bool { scrollOffset < -5 }

    private var weekdaySymbols: [String] {
        Calendar.current.veryShortWeekdaySymbols
    }

    private var displayedWeek: [Date] {
        let monday = weekMonday(offset: currentWeekOffset)
        return (0..<7).map { i in
            Calendar.current.date(byAdding: .day, value: i, to: monday)!
        }
    }

    private var filteredSessions: [FocusSession] {
        historyStore.sessions.filter {
            Calendar.current.isDate($0.startDate, inSameDayAs: uiStore.selectedDate)
        }
    }

    private var headerTitle: String {
        let months = ["Jan","Feb","Mar","Apr","May","Jun",
                      "Jul","Aug","Sep","Oct","Nov","Dec"]
        let isToday = Calendar.current.isDateInToday(uiStore.selectedDate)
        let m = Calendar.current.component(.month, from: uiStore.selectedDate) - 1
        let d = Calendar.current.component(.day,   from: uiStore.selectedDate)
        return "\(months[m]) \(d)\(isToday ? ", Today" : "")"
    }

    var body: some View {
        ZStack(alignment: .top) {
            // Fondo
            Color(hex: "#111116").ignoresSafeArea()
            
            LinearGradient(
                colors: [Color(hex: "#353B60").opacity(0.8), Color(hex: "#111116")],
                startPoint: .top,
                endPoint:   .center
            )
            .ignoresSafeArea()

            // Timeline
            TimelineView(sessions: filteredSessions, scrollOffset: $scrollOffset)

            // Header (Solo per versioni < iOS 26 come overlay)
            if #unavailable(iOS 26) {
                VStack(spacing: 0) {
                    calendarHeader
                        .padding(.horizontal, SIDE_MARGIN)
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

            // Overlays
            if uiStore.isAddSessionVisible {
                AddSessionView()
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        // Native Scroll Edge Effect for iOS 26+
        .applyNativeCalendarHeader(edge: .top) {
            calendarHeader
                .padding(.horizontal, SIDE_MARGIN)
                .padding(.bottom, 20)
                .padding(.top, 60)
        }
        .animation(.easeInOut(duration: 0.3), value: uiStore.isAddSessionVisible)
        .confirmationDialog(
            "Svuota Cronologia",
            isPresented: $showClearConfirm,
            titleVisibility: .visible
        ) {
            Button("Svuota", role: .destructive) {
                historyStore.clearHistory()
                HapticManager.notifySuccess()
            }
            Button("Annulla", role: .cancel) {}
        } message: {
            Text("Sei sicuro di voler eliminare tutte le sessioni del calendario?")
        }
    }

    private var calendarHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(headerTitle)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.4, dampingFraction: 0.9), value: headerTitle)
                Spacer()
                
                HStack(spacing: 12) {
                    Button {
                        HapticManager.impactLight()
                        uiStore.isAddSessionVisible = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(10)
                            .glassBackground(in: Circle())
                    }
                    
                    Button {
                        showClearConfirm = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(10)
                            .glassBackground(in: Circle())
                    }
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    ForEach(-52...52, id: \.self) { offset in
                        let week = weekDays(for: offset)
                        HStack(spacing: 8) {
                            ForEach(week, id: \.self) { day in
                                DayPillView(
                                    day: day,
                                    weekdaySymbols: weekdaySymbols,
                                    isSelected: Calendar.current.isDate(day, inSameDayAs: uiStore.selectedDate),
                                    onTap: { 
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            uiStore.selectedDate = day 
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
                set: { newValue in 
                    if let v = newValue {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            currentWeekOffset = v 
                        }
                    }
                }
            ))
            .scrollIndicators(.hidden)
            .frame(height: 68)
        }
    }

    private func weekDays(for offset: Int) -> [Date] {
        let monday = weekMonday(offset: offset)
        return (0..<7).map { i in
            Calendar.current.date(byAdding: .day, value: i, to: monday)!
        }
    }
}


private struct DayPillView: View {
    let day:        Date
    let weekdaySymbols: [String]
    let isSelected: Bool
    let onTap:      () -> Void

    private var isToday:  Bool { Calendar.current.isDateInToday(day) }
    private var dayInit:  String {
        let idx = Calendar.current.component(.weekday, from: day) - 1
        return weekdaySymbols[idx]
    }
    private var dayNum:   Int { Calendar.current.component(.day, from: day) }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(dayInit)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.5))
                Text("\(dayNum)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .glassBackground(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .opacity(isSelected || isToday ? 1.0 : 0.4)
        }
    }
}

// MARK: – Timeline

private struct TimelineView: View {
    @Environment(FocusHistoryStore.self) private var historyStore
    let sessions:    [FocusSession]
    @Binding var scrollOffset: CGFloat

    var body: some View {
        ScrollView {
            ZStack(alignment: .topLeading) {
                // Tracking dello scroll passivo
                GeometryReader { proxy in
                    let minY = proxy.frame(in: .named("timeline_scroll")).minY
                    Color.clear.onAppear { scrollOffset = minY }
                        .onChange(of: minY) { _, newValue in
                            scrollOffset = newValue
                        }
                }
                .frame(height: 0)

                VStack(spacing: 0) {
                    // Padding differente basato sulla versione per accomodare safeAreaBar vs Overlay
                    adaptiveTimelineTopPadding()
                    
                    ForEach(0..<25, id: \.self) { h in
                        HourRow(hour: h)
                    }
                }

                ForEach(sessions) { session in
                    SessionBlockView(session: session) {
                        historyStore.deleteSession(id: session.id)
                        HapticManager.notifySuccess()
                    }
                }
                .adaptiveTimelineSessionPadding()
                .padding(.leading, 70)
                .padding(.trailing, 20)
            }
            .padding(.bottom, 100)
        }
        .coordinateSpace(name: "timeline_scroll")
        .scrollIndicators(.hidden)
        .adaptiveScrollEdgeEffect()
    }
}

private struct HourRow: View {
    let hour: Int
    var body: some View {
        HStack(spacing: 0) {
            Text(String(format: "%02d:00", hour))
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
                .frame(width: 70, alignment: .center)
                .offset(y: -8)

            Rectangle()
                .fill(.white.opacity(0.15))
                .frame(height: 1)
                .padding(.trailing, 20)
        }
        .frame(height: HOUR_HEIGHT, alignment: .top)
    }
}

private struct SessionBlockView: View {
    let session:  FocusSession
    let onDelete: () -> Void

    private var topOffset: CGFloat {
        let h = Double(Calendar.current.component(.hour,   from: session.startDate))
        let m = Double(Calendar.current.component(.minute, from: session.startDate))
        return CGFloat(h + m / 60) * HOUR_HEIGHT
    }

    private var height: CGFloat {
        max(40, CGFloat(session.duration) * HOUR_HEIGHT / 60)
    }

    private var color: Color { Color(hex: session.color) }

    var body: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: topOffset)
                .allowsHitTesting(false)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.modeTitle)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("\(session.duration) min")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(.horizontal, 16)
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(
                color
                    .opacity(0.8)
                    .overlay(
                        LinearGradient(
                            colors: [.white.opacity(0.2), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .clipShape(.rect(cornerRadius: 16))
            .shadow(color: color.opacity(0.4), radius: 6, x: 0, y: 3)
            .contextMenu {
                Button(role: .destructive, action: onDelete) {
                    Label("Elimina Sessione", systemImage: "trash")
                }
            }
        }
    }
}

// MARK: – Helpers & Extensions

private func weekMonday(offset: Int) -> Date {
    let cal    = Calendar(identifier: .iso8601)
    let today  = Date()
    let monday = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
    return cal.date(byAdding: .weekOfYear, value: offset, to: monday)!
}

extension View {
    @ViewBuilder
    func applyNativeCalendarHeader<Content: View>(edge: VerticalEdge, @ViewBuilder content: () -> Content) -> some View {
        if #available(iOS 26, *) {
            self.safeAreaBar(edge: edge, content: content)
        } else {
            self
        }
    }
    
    @ViewBuilder
    func adaptiveScrollEdgeEffect() -> some View {
        if #available(iOS 26, *) {
            self.scrollEdgeEffectStyle(.soft, for: .all)
        } else {
            self
        }
    }

    @ViewBuilder
    func adaptiveTimelineTopPadding() -> some View {
        if #available(iOS 26, *) {
            // Su iOS 26+ safeAreaBar gestisce lo spazio
            Color.clear.frame(height: 0)
        } else {
            // Su < iOS 26 overlay ha bisogno di padding per non coprire i dati
            Color.clear.frame(height: 220)
        }
    }

    @ViewBuilder
    func adaptiveTimelineSessionPadding() -> some View {
        if #available(iOS 26, *) {
            self.padding(.top, 0)
        } else {
            self.padding(.top, 220)
        }
    }
}
