import SwiftUI

struct ModeSelectionView: View {
    @Environment(FocusModesStore.self) private var modesStore
    @Environment(UIStateStore.self) private var uiStore

    @State private var showNewMode    = false
    @State private var renameTarget:  FocusMode? = nil
    
    @State private var offsetY: CGFloat = 600
    @State private var opacity: Double  = 0

    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.5 * opacity)
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

                        // Title bar
                        HStack {
                            Text("Modes")
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
                        .padding(.bottom, 12)

                        // Mode list
                        ScrollView {
                            LazyVStack(spacing: 2) {
                                ForEach(modesStore.modes) { mode in
                                    ModeRowView(
                                        mode:      mode,
                                        isCurrent: mode.id == modesStore.currentMode.id,
                                        isDefault: mode.id == modesStore.defaultModeId,
                                        onSelect: {
                                            HapticManager.selection()
                                            modesStore.setCurrentMode(mode)
                                            modesStore.resetTimer()
                                            close()
                                        },
                                        onRename: {
                                            renameTarget = mode
                                        },
                                        onSetDefault: {
                                            modesStore.setDefaultMode(id: mode.id, isActive: false)
                                            HapticManager.impactLight()
                                        },
                                        onDelete: {
                                            modesStore.deleteMode(id: mode.id, isActive: false)
                                            HapticManager.impactMedium()
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 12)
                        }
                        .frame(maxHeight: 304)

                        // Add new mode button
                        Button {
                            HapticManager.impactLight()
                            showNewMode = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("New Mode")
                                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .glassBackground(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
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
        .onAppear { open() }
        .sheet(isPresented: $showNewMode) {
            NewModeView()
        }
        .sheet(item: $renameTarget) { mode in
            RenameModeView(mode: mode)
        }
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
            uiStore.isModeSelectionVisible = false
        }
    }
}

// MARK: – Mode row

private struct ModeRowView: View {
    let mode:        FocusMode
    let isCurrent:   Bool
    let isDefault:   Bool
    let onSelect:    () -> Void
    let onRename:    () -> Void
    let onSetDefault:() -> Void
    let onDelete:    () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(getIconColor(mode.icon).opacity(0.2))
                    .frame(width: 40, height: 40)
                Image(systemName: sfSymbol(for: mode.icon))
                    .font(.system(size: 16))
                    .foregroundStyle(getIconColor(mode.icon))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(mode.name)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text("\(mode.duration) min")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            // Default star
            if isDefault {
                Image(systemName: "star.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "#FFD60A"))
            }

            // Checkmark if current
            if isCurrent {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(isCurrent ? Color.white.opacity(0.08) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .contextMenu {
            Button { onRename() }    label: { Label("Rename",      systemImage: "pencil") }
            Button { onSetDefault() } label: { Label("Set as Default", systemImage: "star") }
            Divider()
            Button(role: .destructive) { onDelete() } label: { Label("Delete", systemImage: "trash") }
        }
    }
}

