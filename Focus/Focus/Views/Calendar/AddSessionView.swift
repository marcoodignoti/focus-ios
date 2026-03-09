import SwiftUI
import Foundation
import Observation

struct AddSessionView: View {
    @Environment(FocusModesStore.self) private var modesStore
    @Environment(FocusHistoryStore.self) private var historyStore
    @Environment(UIStateStore.self) private var uiStore

    @State private var selectedMode: FocusMode
    @State private var startTime: Date
    @State private var duration: Int
    
    @State private var offsetY: CGFloat = 600
    @State private var opacity: Double  = 0

    init() {
        let first = FocusMode.defaults[0]
        _selectedMode = State(initialValue: first)
        _duration     = State(initialValue: first.duration)
        _startTime    = State(initialValue: Date())
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Backdrop
            Color.black.opacity(0.4 * opacity)
                .ignoresSafeArea()
                .onTapGesture { close() }

            VStack(spacing: 0) {
                Spacer()
                
                GlassCard(cornerRadius: 32) {
                    VStack(spacing: 0) {
                        // Grabber
                        Capsule()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 36, height: 5)
                            .padding(.top, 12)

                        // Title
                        HStack {
                            Text("Nuova Sessione")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            Spacer()
                            // Close button
                            Button {
                                HapticManager.impactLight()
                                close()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.7))
                                    .padding(10)
                                    .background(.ultraThinMaterial)
                                    .clipShape(.circle)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 8)

                        // Contenuto senza ScrollView per visibilità immediata
                        VStack(alignment: .leading, spacing: 24) {
                            
                            // 1. Mode picker
                            VStack(alignment: .leading, spacing: 10) {
                                sectionLabel("Modalità")
                                ScrollView(.horizontal) {
                                    HStack(spacing: 10) {
                                        ForEach(modesStore.modes) { mode in
                                            let isActive = mode.id == selectedMode.id
                                            let color    = getIconColor(mode.icon)
                                            Button {
                                                HapticManager.impactLight()
                                                selectedMode = mode
                                                duration     = mode.duration
                                            } label: {
                                                HStack(spacing: 8) {
                                                    Image(systemName: sfSymbol(for: mode.icon))
                                                        .font(.system(size: 14))
                                                        .foregroundStyle(isActive ? Color(hex: "#111116") : .white)
                                                    Text(mode.name)
                                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                                        .foregroundStyle(isActive ? Color(hex: "#111116") : .white)
                                                }
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(isActive ? color : .white.opacity(0.08))
                                                .clipShape(.capsule)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                                .scrollIndicators(.hidden)
                                .padding(.horizontal, -20)
                            }

                            // 2. Start time (più compatto)
                            VStack(alignment: .leading, spacing: 10) {
                                sectionLabel("Ora di inizio")
                                DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                                    .datePickerStyle(.wheel)
                                    .labelsHidden()
                                    .colorScheme(.dark)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 110) // Altezza ridotta per compattezza
                                    .clipped()
                                    .glassBackground(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                            }

                            // 3. Duration
                            VStack(alignment: .leading, spacing: 10) {
                                sectionLabel("Durata · \(duration) min")
                                RulerPickerView(value: $duration)
                                    .frame(height: 88) // Altezza ridotta
                                    .glassBackground(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                            }
                            
                            // 4. Save button
                            Button {
                                save()
                            } label: {
                                Text("Salva Sessione")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .glassBackground(in: Capsule())
                            }
                            .padding(.top, 4)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
            .offset(y: offsetY)
            .gesture(
                DragGesture()
                    .onChanged { g in
                        if g.translation.height > 0 {
                            offsetY = g.translation.height
                        }
                    }
                    .onEnded { g in
                        if g.translation.height > 100 || g.predictedEndTranslation.height > 300 {
                            close()
                        } else {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                offsetY = 0
                            }
                        }
                    }
            )
        }
        .onAppear {
            setupInitialState()
            open()
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .tracking(1)
            .foregroundStyle(.white.opacity(0.5))
            .textCase(.uppercase)
    }
    
    private func setupInitialState() {
        if let first = modesStore.modes.first {
            selectedMode = first
            duration     = first.duration
        }
        
        let cal = Calendar.current
        let date = uiStore.selectedDate
        let d   = cal.date(bySettingHour: cal.component(.hour, from: date),
                           minute: 0, second: 0, of: date) ?? date
        startTime = d
    }

    private func open() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            offsetY = 0
            opacity = 1
        }
    }

    private func close() {
        withAnimation(.easeIn(duration: 0.25)) {
            offsetY = 600
            opacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            uiStore.isAddSessionVisible = false
        }
    }

    private func save() {
        HapticManager.notifySuccess()
        let cal  = Calendar.current
        var comps = cal.dateComponents([.year, .month, .day], from: uiStore.selectedDate)
        comps.hour   = cal.component(.hour,   from: startTime)
        comps.minute = cal.component(.minute, from: startTime)
        let finalDate = cal.date(from: comps) ?? startTime

        historyStore.addSession(
            modeId:    selectedMode.id,
            modeTitle: selectedMode.name,
            color:     getIconColorHex(selectedMode.icon),
            startTime: finalDate.timeIntervalSince1970 * 1000,
            duration:  duration
        )
        close()
    }
}

