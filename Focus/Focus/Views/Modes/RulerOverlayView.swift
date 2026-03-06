import SwiftUI

struct RulerOverlayView: View {
    @Binding var isVisible: Bool
    let initialValue: Int
    let onConfirm:    (Int) -> Void

    @State private var duration: Int
    @State private var offsetY:  CGFloat = 600
    @State private var opacity:  Double  = 0

    init(isVisible: Binding<Bool>, initialValue: Int, onConfirm: @escaping (Int) -> Void) {
        _isVisible   = isVisible
        self.initialValue = initialValue
        self.onConfirm    = onConfirm
        _duration = State(initialValue: initialValue)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Backdrop
            Color.black.opacity(0.4 * opacity)
                .ignoresSafeArea()
                .onTapGesture { close() }

            // Sheet
            VStack(spacing: 0) {
                // Grabber
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 36, height: 5)
                    .padding(.top, 12)

                // Header
                Text("Adjust duration")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .tracking(1)
                    .foregroundColor(.white.opacity(0.5))
                    .textCase(.uppercase)
                    .padding(.top, 16)

                // Ruler
                RulerPickerView(value: $duration)
                    .frame(height: 100)
                    .glassBackground(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                // Confirm button
                Button {
                    HapticManager.impactMedium()
                    onConfirm(duration)
                    close()
                } label: {
                    Text("Set Time")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 64)
                        .glassBackground(in: Capsule())
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
            .glassBackground(in: RoundedRectangle(cornerRadius: 32, style: .continuous))
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
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
        .onChange(of: isVisible) { _, newValue in
            if newValue { open() } else { close() }
        }
    }

    private func open() {
        duration = initialValue
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
            isVisible = false
        }
    }
}
