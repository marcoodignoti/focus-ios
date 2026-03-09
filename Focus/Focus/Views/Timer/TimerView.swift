import SwiftUI

struct TimerView: View {
    @Environment(FocusModesStore.self) private var modesStore
    @Environment(FocusHistoryStore.self) private var historyStore
    @Environment(UIStateStore.self) private var uiStore
    
    // ViewModel is initialized once with its dependencies
    @State private var viewModel: TimerViewModel?

    var body: some View {
        Group {
            if let vm = viewModel {
                timerContent(vm)
            } else {
                Color(hex: "#111116")
                    .onAppear {
                        viewModel = TimerViewModel(modesStore: modesStore, historyStore: historyStore)
                    }
            }
        }
    }

    @ViewBuilder
    private func timerContent(_ vm: TimerViewModel) -> some View {
        ZStack {
            // Backgrounds
            Color(hex: "#111116").ignoresSafeArea()
            if vm.isActive {
                Color(hex: "#1C1D2A")
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.5), value: vm.isActive)
            }

            // Full-screen Hold-to-stop gesture
            Color.clear
                .contentShape(Rectangle())
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if vm.isActive && !vm.isHolding { vm.beginHold() }
                        }
                        .onEnded { _ in
                            if vm.isHolding { vm.cancelHold() }
                        }
                )
                .ignoresSafeArea()
                .allowsHitTesting(vm.isActive)

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 0) {
                    // Phase label
                    Text(modesStore.pomodoroState.phase.displayName.uppercased())
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .tracking(1.5)
                        .foregroundStyle(.white.opacity(0.6))
                        .opacity(vm.isActive ? 1 : 0)
                        .padding(.bottom, 12)

                    // Timer digits
                    Button(action: {
                        if !vm.isActive {
                            HapticManager.impactLight()
                            uiStore.isRulerVisible = true
                        }
                    }) {
                        TimerDisplayView(
                            totalSeconds: vm.calculateDuration(),
                            timeRemaining: vm.timeRemaining
                        )
                        .opacity(vm.isPaused ? 0.6 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: vm.isPaused)
                    }
                    .buttonStyle(.plain)
                    .disabled(vm.isActive)
                    .id("\(modesStore.timerResetKey)-\(modesStore.pomodoroState.phase)-\(modesStore.pomodoroState.sessionCount)")

                    // Mode selector
                    ModeSelectorView(mode: modesStore.currentMode) {
                        uiStore.isModeSelectionVisible = true
                    }
                    .padding(.top, 10)
                    .opacity(vm.isActive ? 0 : 1)

                    // Session dots
                    if vm.isActive {
                        VStack(spacing: 24) {
                            HStack(spacing: 8) {
                                ForEach(1...4, id: \.self) { i in
                                    Circle()
                                        .fill(dotColor(for: i))
                                        .frame(width: 6, height: 6)
                                        .scaleEffect(isDotScaled(for: i) ? 1.2 : 1.0)
                                }
                            }
                            
                            Button(action: {
                                if vm.isPaused { vm.resumeFocus() }
                                else { vm.pauseFocus() }
                            }) {
                                Image(systemName: vm.isPaused ? "play.fill" : "pause.fill")
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

                if !vm.isActive {
                    StartButtonView(label: "Start Focus", onPress: vm.startFocus)
                        .padding(.bottom, 110)
                        .transition(.opacity)
                } else {
                    VStack(spacing: 14) {
                        Text("Hold to stop focus")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(vm.isHolding ? 1.0 : 0.7))

                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(.white.opacity(0.25))
                                .frame(width: 180, height: 8)
                            Capsule()
                                .fill(.white)
                                .frame(width: 180 * vm.holdProgress, height: 8)
                        }
                    }
                    .padding(.bottom, 110)
                    .transition(.opacity)
                }

                if !vm.isActive {
                    Capsule()
                        .fill(.white.opacity(0.2))
                        .frame(width: 36, height: 5)
                        .padding(.bottom, 14)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.4), value: vm.isActive)
        }
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
        .onChange(of: modesStore.timerResetKey) {
            vm.resetDuration()
        }
        .onChange(of: modesStore.currentMode.duration) {
            vm.resetDuration()
        }
    }

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
}
