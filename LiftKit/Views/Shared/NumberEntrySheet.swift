import SwiftUI

struct NumberEntryItem: Identifiable {
    let id = UUID()
    let title: String
    let min: Double
    let max: Double
    let current: Double
    let onCommit: (Double) -> Void
}

struct NumberEntrySheet: View {
    let item: NumberEntryItem
    @Environment(\.dismiss) private var dismiss
    @State private var text: String = ""
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: LKSpacing.lg) {
                Spacer()
                Text(item.title)
                    .font(LKFont.heading)
                    .foregroundStyle(LKColors.Hex.textPrimary)

                TextField("", text: $text)
                    .font(LKFont.timer(48))
                    .foregroundStyle(LKColors.Hex.accent)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .focused($focused)

                Spacer()

                Button("Done") {
                    commit()
                }
                .buttonStyle(LKPrimaryButtonStyle())
                .padding(.horizontal, LKSpacing.lg)
                .padding(.bottom, LKSpacing.lg)
            }
            .background(LKColors.Hex.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(LKColors.Hex.textSecondary)
                }
            }
        }
        .presentationDetents([.height(280)])
        .onAppear {
            text = item.current == 0 ? "" : String(Int(item.current))
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { focused = true }
        }
    }

    private func commit() {
        let value = Double(text) ?? item.current
        let clamped = max(item.min, min(item.max, value))
        item.onCommit(clamped)
        dismiss()
    }
}
