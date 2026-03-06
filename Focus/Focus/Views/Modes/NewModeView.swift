import SwiftUI

struct NewModeView: View {
    @Environment(FocusModesStore.self) private var modesStore
    @Environment(\.dismiss) private var dismiss

    @State private var name:         String = ""
    @State private var selectedIcon: String = "flash"
    @State private var duration:     Int    = 25

    private var isSaveDisabled: Bool { name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#111116").ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        // Name
                        sectionLabel("Name")
                        TextField("e.g. Deep Work", text: $name)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(16)
                            .background(.white.opacity(0.05))
                            .clipShape(.capsule)
                            .submitLabel(.done)
                            .onSubmit { if !isSaveDisabled { save() } }

                        // Icon
                        sectionLabel("Icon")
                        ScrollView(.horizontal) {
                            HStack(spacing: 12) {
                                ForEach(CURATED_ICONS, id: \.self) { icon in
                                    Button {
                                        HapticManager.impactLight()
                                        selectedIcon = icon
                                    } label: {
                                        Image(systemName: sfSymbol(for: icon))
                                            .font(.system(size: 24))
                                            .foregroundStyle(selectedIcon == icon ? Color(hex: "#111116") : .white)
                                            .frame(width: 56, height: 56)
                                            .background(selectedIcon == icon ? .white : .white.opacity(0.07))
                                            .clipShape(.rect(cornerRadius: 16))
                                    }
                                    .accessibilityLabel("\(icon) icon")
                                    .accessibilityAddTraits(selectedIcon == icon ? .isSelected : [])
                                }
                            }
                        }
                        .scrollIndicators(.hidden)

                        // Duration
                        sectionLabel("Duration")
                        RulerPickerView(value: $duration)
                            .frame(height: 100)
                            .background(.white.opacity(0.03))
                            .clipShape(.rect(cornerRadius: 20))
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white.opacity(0.7))
                }
                ToolbarItem(placement: .principal) {
                    Text("New Mode")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(isSaveDisabled ? .white.opacity(0.3) : .white)
                        .disabled(isSaveDisabled)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .tracking(1)
            .foregroundStyle(.white.opacity(0.6))
            .textCase(.uppercase)
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        HapticManager.notifySuccess()
        modesStore.createMode(name: trimmed, duration: duration, icon: selectedIcon)
        dismiss()
    }
}


