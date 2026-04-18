import SwiftUI

struct WorkoutTypePickerView: View {
    @Environment(WorkoutViewModel.self) private var vm
    @Binding var isPresented: Bool
    let onStartWorkout: () -> Void

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let hPad = LKSpacing.md
                let spacing = LKSpacing.sm
                let cardW = (geo.size.width - hPad * 2 - spacing) / 2
                // 3 rows of cards; subtract nav bar (~56pt) + top/bottom padding
                let availH = geo.size.height - 56 - hPad * 2 - spacing * 2
                let cardH = max(100, availH / 3)

                LazyVGrid(
                    columns: [GridItem(.fixed(cardW), spacing: spacing),
                              GridItem(.fixed(cardW), spacing: spacing)],
                    spacing: spacing
                ) {
                    ForEach(TimerType.allCases, id: \.self) { type in
                        NavigationLink(value: type) {
                            WorkoutTypeCard(type: type)
                                .frame(height: cardH)
                        }
                        .buttonStyle(.plain)
                        .simultaneousGesture(TapGesture().onEnded {
                            HapticManager.shared.buttonTap()
                            vm.resetSetup(for: type)
                        })
                    }
                }
                .padding(.horizontal, hPad)
                .padding(.top, hPad)
            }
            .background(LKColors.Hex.background)
            .navigationTitle("Choose Workout Type")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { isPresented = false }
                        .foregroundStyle(LKColors.Hex.textSecondary)
                }
            }
            .navigationDestination(for: TimerType.self) { _ in
                WorkoutSetupView {
                    isPresented = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        onStartWorkout()
                    }
                }
            }
        }
    }
}

struct WorkoutTypeCard: View {
    let type: TimerType

    var body: some View {
        VStack(spacing: LKSpacing.sm) {
            Image(systemName: type.icon)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(LKColors.Hex.accent)
            Text(type.rawValue)
                .font(LKFont.bodyBold)
                .foregroundStyle(LKColors.Hex.textPrimary)
                .lineLimit(1)
            Text(type.subtitle)
                .font(LKFont.caption)
                .foregroundStyle(LKColors.Hex.textMuted)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(LKSpacing.md)
        .background(LKColors.Hex.surface)
        .clipShape(RoundedRectangle(cornerRadius: LKRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: LKRadius.large)
                .strokeBorder(LKColors.Hex.surfaceElevated, lineWidth: 1)
        )
    }
}
