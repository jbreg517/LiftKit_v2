import SwiftUI

struct WorkoutTypePickerView: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (TimerType) -> Void

    let columns = [GridItem(.flexible(), spacing: LKSpacing.sm),
                   GridItem(.flexible(), spacing: LKSpacing.sm)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: LKSpacing.sm) {
                    ForEach(TimerType.allCases, id: \.self) { type in
                        WorkoutTypeCard(type: type) {
                            HapticManager.shared.buttonTap()
                            onSelect(type)
                        }
                    }
                }
                .padding(LKSpacing.md)
            }
            .background(LKColors.Hex.background)
            .navigationTitle("Choose Workout Type")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(LKColors.Hex.textSecondary)
                }
            }
        }
    }
}

struct WorkoutTypeCard: View {
    let type: TimerType
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
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
            .frame(maxWidth: .infinity)
            .padding(LKSpacing.md)
            .background(LKColors.Hex.surface)
            .clipShape(RoundedRectangle(cornerRadius: LKRadius.large))
            .overlay(
                RoundedRectangle(cornerRadius: LKRadius.large)
                    .strokeBorder(LKColors.Hex.surfaceElevated, lineWidth: 1)
            )
        }
    }
}
