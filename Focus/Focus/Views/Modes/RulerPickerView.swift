import SwiftUI

struct RulerPickerView: View {
    @Binding var value: Int
    @State private var scrollID: Int?
    
    private let MIN_VAL = 0
    private let MAX_VAL = 120
    private let SPACING: CGFloat = 20 // Spazio esatto tra ogni minuto

    var body: some View {
        GeometryReader { geo in
            let midX = geo.size.width / 2
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: 0) {
                    ForEach(MIN_VAL...MAX_VAL, id: \.self) { v in
                        TickView(v: v, midX: midX)
                            .frame(width: SPACING)
                            .id(v)
                    }
                }
                .scrollTargetLayout()
            }
            // Padding nativo calcolato dinamicamente
            .safeAreaPadding(.horizontal, max(0, midX - (SPACING / 2)))
            .scrollPosition(id: $scrollID, anchor: .center)
            .scrollTargetBehavior(FiveMinuteSnapBehavior(spacing: SPACING))
            .clipped()
            .coordinateSpace(name: "ruler")
            .onAppear {
                // Sincronizzazione iniziale
                scrollID = value
                
                // Rinforzo dopo un micro-delay per superare l'animazione del Bottom Sheet
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    scrollID = value
                }
            }
            .onChange(of: midX) { _, newMidX in
                // Se la geometria cambia (es. il pannello finisce di aprirsi), ri-centriamo
                if newMidX > 0 {
                    scrollID = value
                }
            }
            .onChange(of: scrollID) { _, newValue in
                // Aggiorna il valore esterno solo su sosta valida
                if let newValue, newValue % 5 == 0, newValue != value {
                    value = newValue
                    HapticManager.selection()
                }
            }
            .onChange(of: value) { _, newValue in
                if newValue != scrollID {
                    scrollID = newValue
                }
            }
            
            // Indicatore centrale fisso
            Capsule()
                .fill(Color(hex: "#FF453A"))
                .frame(width: 8, height: 50)
                .position(x: midX, y: geo.size.height - 30)
                .allowsHitTesting(false)
        }
    }
}

// MARK: - Snapping Behavior
struct FiveMinuteSnapBehavior: ScrollTargetBehavior {
    let spacing: CGFloat
    func updateTarget(_ target: inout ScrollTarget, context: TargetContext) {
        let unit = spacing * 5
        let x = target.rect.origin.x
        target.rect.origin.x = (x / unit).rounded() * unit
    }
}

private struct TickView: View {
    let v: Int
    let midX: CGFloat
    
    var body: some View {
        VStack(spacing: 12) {
            if v % 5 == 0 {
                Text("\(v)")
                    .font(.system(size: 24, weight: .heavy, design: .rounded).monospacedDigit())
                    .foregroundStyle(.white)
                    .fixedSize()
                    .visualEffect { content, proxy in
                        let frame = proxy.frame(in: .named("ruler"))
                        let distance = abs(frame.midX - midX)
                        // Magnificazione fluida fino a 1.5x
                        let scale = 1.0 + max(0, (1.0 - (distance / 80)) * 0.5)
                        let opacity = Double(max(0.3, 1.0 - (distance / 120)))
                        return content.scaleEffect(scale).opacity(opacity)
                    }
            } else {
                Text("0").font(.system(size: 24)).opacity(0).fixedSize()
            }
            
            // Usiamo Capsule per mantenere i bordi arrotondati indipendentemente dalla larghezza
            Capsule()
                .fill(v % 5 == 0 ? .white : .white.opacity(0.2))
                .frame(
                    width: v % 5 == 0 ? 8 : 6, // Larghezza (spessore)
                    height: v % 5 == 0 ? 42 : 20 // Altezza
                )
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, 12)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var value = 25
        var body: some View {
            ZStack {
                Color(hex: "#111116").ignoresSafeArea()
                
                VStack(spacing: 50) {
                    Text("\(value) min")
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    
                    RulerPickerView(value: $value)
                        .frame(height: 120)
                        .background(.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .padding(.horizontal)
                }
            }
        }
    }
    return PreviewWrapper()
}
