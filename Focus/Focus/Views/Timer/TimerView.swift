import SwiftUI
import Combine

struct TimerView: View {
    @Environment(FocusModesStore.self) private var modesStore
    @Environment(FocusHistoryStore.self) private var historyStore
    @Environment(UIStateStore.self) private var uiStore

    // Timer state
    @State private var isActive            = false
    @State private var isPaused            = false
    @State private var timeRemaining:Double = 0
    @State private var sessionStartTime:   Date?  = nil
    @State private var timeElapsedBeforePause: TimeInterval = 0
    @State private var accumulatedMinutes  = 0

    // Hold-to-stop
    @State private var holdProgress: Double = 0
    @State private var isHolding            = false
    @State private var holdTimer:           Timer? = nil

    // Smooth 0.1 s tick
    private let ticker = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    // MARK: – Derived

    private var currentDurationSeconds: Double {
        let fs = Double(modesStore.currentMode.duration * 60)
        switch modesStore.pomodoroState.phase {
        case .focus:      return fs
        case .shortBreak:
            let b = fs * 0.2
            return b > 60 ? (ceil(b / 60) * 60) : ceil(b)
        case .longBreak:
            let b = fs * 0.6
            return b > 60 ? (ceil(b / 60) * 60) : ceil(b)
        }
    }

    // MARK: – Body

    var body: some View {
        ZStack {
            // Backgrounds
            Color(hex: "#111116").ignoresSafeArea()
            if isActive {
                Color(hex: "#1C1D2A")
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.5), value: isActive)
            }

            // Full-screen Hold-to-stop gesture (only when active)
            Color.clear
                .contentShape(Rectangle())
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if isActive && !isHolding { beginHold() }
                        }
                        .onEnded { _ in
                            if isHolding { cancelHold() }
                        }
                )
                .ignoresSafeArea()
                .allowsHitTesting(isActive)

            VStack(spacing: 0) {
                Spacer()

                // ── Top section ──────────────────────────────────────────────
                VStack(spacing: 0) {
                    // Phase label
                    Text(modesStore.pomodoroState.phase.displayName.uppercased())
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .tracking(1.5)
                        .foregroundStyle(.white.opacity(0.6))
                        .opacity(isActive ? 1 : 0)
                        .padding(.bottom, 12)

                    // Timer digits
                    Button(action: {
                        if !isActive {
                            HapticManager.impactLight()
                            uiStore.isRulerVisible = true
                        }
                    }) {
                        TimerDisplayView(
                            totalSeconds: currentDurationSeconds,
                            timeRemaining: timeRemaining
                        )
                        .opacity(isPaused ? 0.6 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: isPaused)
                    }
                    .buttonStyle(.plain)
                    .disabled(isActive)
                    .id("\(modesStore.timerResetKey)-\(modesStore.pomodoroState.phase)-\(modesStore.pomodoroState.sessionCount)")

                    // Mode selector
                    ModeSelectorView(mode: modesStore.currentMode) {
                        uiStore.isModeSelectionVisible = true
                    }
                    .padding(.top, 10)
                    .opacity(isActive ? 0 : 1)

                    // Session dots
                    if isActive {
                        VStack(spacing: 24) {
                            HStack(spacing: 8) {
                                ForEach(1...4, id: \.self) { i in
                                    Circle()
                                        .fill(dotColor(for: i))
                                        .frame(width: 6, height: 6)
                                        .scaleEffect(isDotScaled(for: i) ? 1.2 : 1.0)
                                }
                            }
                            
                            // 2. Pause / Resume Button (Middle)
                            Button(action: {
                                if isPaused { resumeFocus() }
                                else { pauseFocus() }
                            }) {
                                Image(systemName: isPaused ? "play.fill" : "pause.fill")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 64, height: 64)
                                    .glassBackground(in: Circle())
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                        .padding(.top, 20)
                        .transition(.opacity)
                    }
                }

                Spacer()

                // ── Bottom section ───────────────────────────────────────────
                if !isActive {
                    StartButtonView(label: "Start Focus", onPress: startFocus)
                        .padding(.bottom, 110)
                        .transition(.opacity)
                } else {
                    // 3. Hold-to-stop UI (Restored)
                    VStack(spacing: 14) {
                        Text("Hold to stop focus")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(isHolding ? 1.0 : 0.7))

                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(.white.opacity(0.25))
                                .frame(width: 180, height: 8)
                            Capsule()
                                .fill(.white)
                                .frame(width: 180 * holdProgress, height: 8)
                        }
                    }
                    .padding(.bottom, 110)
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.4), value: isActive)
        }
        // ── Overlays ─────────────────────────────────────────────────────────
        .overlay {
            if uiStore.isModeSelectionVisible {
                ModeSelectionView()
                    .transition(.opacity)
            }
        }
        .overlay(alignment: .bottom) {
            if uiStore.isRulerVisible {
                @Bindable var uiBindable = uiStore
                RulerOverlayView(
                    isVisible:    $uiBindable.isRulerVisible,
                    initialValue: modesStore.currentMode.duration
                ) { value in
                    modesStore.updateModeParams(
                        id: modesStore.currentMode.id,
                        updates: ModeUpdates(duration: value)
                    )
                }
            }
        }
        // ── Timer tick ───────────────────────────────────────────────────────
        .onReceive(ticker) { _ in
            guard isActive, !isPaused, let start = sessionStartTime else { return }
            
            let elapsedSinceStart = Date().timeIntervalSince(start)
            let totalElapsed = timeElapsedBeforePause + elapsedSinceStart
            let total = currentDurationSeconds
            
            if totalElapsed < total {
                timeRemaining = total - totalElapsed
            } else {
                timeRemaining = 0
                handleTimerComplete()
            }
        }
        // ── Reset when store signals a new timer ─────────────────────────────
        .onChange(of: modesStore.timerResetKey) {
            if !isActive {
                timeRemaining = currentDurationSeconds
            }
        }
        .onChange(of: currentDurationSeconds) {
            if !isActive {
                timeRemaining = currentDurationSeconds
            }
        }
        .onAppear {
            if !isActive {
                timeRemaining = currentDurationSeconds
            }
        }
    }

    // MARK: – Dot helpers

    private func dotColor(for i: Int) -> Color {
        let sc = modesStore.pomodoroState.sessionCount
        let phase = modesStore.pomodoroState.phase
        if i < sc { return .white }
        if i == sc && phase == .focus { return Color(hex: "#4CD964") }
        if i == sc && phase != .focus { return Color(hex: "#FF9500") }
        return .white.opacity(0.2)
    }

    private func isDotScaled(for i: Int) -> Bool {
        i == modesStore.pomodoroState.sessionCount
    }

    // MARK: – Timer logic

    private func startFocus() {
        HapticManager.impactMedium()
        sessionStartTime       = Date()
        timeElapsedBeforePause = 0
        isActive               = true
        isPaused               = false
        timeRemaining          = currentDurationSeconds
        accumulatedMinutes     = 0
    }
    
    private func pauseFocus() {
        HapticManager.impactLight()
        if let start = sessionStartTime {
            timeElapsedBeforePause += Date().timeIntervalSince(start)
        }
        sessionStartTime = nil
        isPaused = true
    }
    
    private func resumeFocus() {
        HapticManager.impactLight()
        sessionStartTime = Date()
        isPaused = false
    }

    private func stopFocus() {
        saveAccumulatedSession()
        isActive               = false
        isPaused               = false
        sessionStartTime       = nil
        timeElapsedBeforePause = 0
        modesStore.resetTimer()
        modesStore.resetPomodoro()
    }

    private func saveAccumulatedSession() {
        guard accumulatedMinutes > 0 else { return }
        let start = Date().addingTimeInterval(-Double(accumulatedMinutes * 60))
        
        historyStore.addSession(
            modeId:    modesStore.currentMode.id,
            modeTitle: modesStore.currentMode.name,
            color:     getIconColorHex(modesStore.currentMode.icon),
            startTime: start.timeIntervalSince1970 * 1000,
            duration:  accumulatedMinutes
        )
        accumulatedMinutes = 0
    }

    private func handleTimerComplete() {
        HapticManager.notifySuccess()

        if modesStore.pomodoroState.phase == .focus {
            accumulatedMinutes += modesStore.currentMode.duration
        }
        if modesStore.pomodoroState.phase == .longBreak {
            saveAccumulatedSession()
        }

        modesStore.nextPomodoroPhase()
        sessionStartTime       = Date() 
        timeElapsedBeforePause = 0
        isActive               = true
        isPaused               = false
        timeRemaining          = currentDurationSeconds
    }

    // MARK: – Hold-to-stop

    private func beginHold() {
        isHolding    = true
        holdProgress = 0
        HapticManager.impactLight()

        let startTime = Date()
        let duration: Double = 2.0

        holdTimer = Timer.scheduledTimer(withTimeInterval: 1 / 60.0, repeats: true) { t in
            guard isHolding else { t.invalidate(); return }
            let elapsed  = Date().timeIntervalSince(startTime)
            let progress = min(elapsed / duration, 1.0)
            withAnimation(.linear(duration: 0.05)) {
                holdProgress = progress
            }
            if progress >= 1.0 {
                t.invalidate()
                HapticManager.notifyWarning()
                stopFocus()
                isHolding    = false
                holdProgress = 0
            }
        }
    }

    private func cancelHold() {
        isHolding = false
        holdTimer?.invalidate()
        holdTimer = nil
        withAnimation(.easeOut(duration: 0.3)) {
            holdProgress = 0
        }
    }
}

#Preview {
    TimerView()
        .environment(FocusModesStore())
        .environment(FocusHistoryStore())
        .environment(UIStateStore())
}
