import SwiftUI
import SwiftData

struct WorkoutHomeView: View {
    @Environment(WorkoutViewModel.self) private var vm
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \WorkoutTemplate.lastUsedAt, order: .reverse) private var templates: [WorkoutTemplate]
    @Query private var profiles: [UserProfile]

    @State private var showTypePicker = false
    @State private var showLogin = false
    @State private var showCreateWorkout = false
    @State private var showAllTemplates = false
    @State private var showActiveWorkout = false
    @State private var selectedSchedule: WorkoutSchedule? = nil
    @State private var navigateToSession: WorkoutSession? = nil

    private var profile: UserProfile? { profiles.first }
    private var isPremium: Bool { profile?.isPremium == true }
    private var maxVisible: Int { isPremium ? UserProfile.maxVisibleTemplates : UserProfile.maxFreeTemplates }
    private var visibleTemplates: [WorkoutTemplate] { Array(templates.prefix(maxVisible)) }
    private var atFreeLimit: Bool { !isPremium && templates.count >= UserProfile.maxFreeTemplates }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: LKSpacing.lg) {
                    headerRow

                    heroButton

                    if isPremium {
                        WorkoutCalendarView(
                            navigateToSession: $navigateToSession,
                            selectedSchedule: $selectedSchedule
                        )
                        .padding(.horizontal, LKSpacing.md)
                    }

                    plansSection
                }
                .padding(.top, LKSpacing.md)
                .padding(.bottom, LKSpacing.xxl)
            }
            .background(LKColors.Hex.background)
            .navigationBarHidden(true)
            .navigationDestination(item: $navigateToSession) { session in
                WorkoutDetailView(session: session)
            }
        }
        .sheet(isPresented: $showTypePicker) {
            WorkoutTypePickerView(isPresented: $showTypePicker) {
                showActiveWorkout = true
            }
        }
        .sheet(isPresented: $showLogin) {
            LoginView()
        }
        .sheet(isPresented: $showCreateWorkout) {
            CreateWorkoutView { showActiveWorkout = true }
        }
        .sheet(item: $selectedSchedule) { schedule in
            ScheduleEditView(schedule: schedule)
        }
        .fullScreenCover(isPresented: $showActiveWorkout) {
            ActiveWorkoutView()
        }
    }

    private var headerRow: some View {
        HStack {
            Text("LiftKit")
                .font(.system(size: 34, weight: .heavy))
                .foregroundStyle(LKColors.Hex.textPrimary)

            Spacer()

            if let p = profile {
                HStack(spacing: LKSpacing.xs) {
                    Image(systemName: "person.fill")
                    Text(p.displayName ?? "Premium")
                    if p.isPremium {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(LKColors.Hex.accent)
                    }
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(LKColors.Hex.textSecondary)
                .padding(.horizontal, LKSpacing.md)
                .padding(.vertical, LKSpacing.xs + 2)
                .overlay(
                    Capsule().strokeBorder(LKColors.Hex.surfaceElevated, lineWidth: 1)
                )
            } else {
                Button { showLogin = true } label: {
                    HStack(spacing: LKSpacing.xs) {
                        Image(systemName: "person.fill")
                        Text("Log In")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(LKColors.Hex.textSecondary)
                    .padding(.horizontal, LKSpacing.md)
                    .padding(.vertical, LKSpacing.xs + 2)
                    .overlay(
                        Capsule().strokeBorder(LKColors.Hex.surfaceElevated, lineWidth: 1)
                    )
                }
                .accessibilityLabel("Log In")
            }
        }
        .padding(.horizontal, LKSpacing.md)
    }

    private var heroButton: some View {
        Button {
            HapticManager.shared.buttonTap()
            showTypePicker = true
        } label: {
            HStack(spacing: LKSpacing.sm) {
                Image(systemName: "play.fill").font(.title3)
                Text("Start Workout Timer")
            }
        }
        .buttonStyle(LKPrimaryButtonStyle())
        .padding(.horizontal, LKSpacing.md)
        .accessibilityHint("Choose a workout type to start")
        .accessibilityLabel("Start Workout Timer")
    }

    private var plansSection: some View {
        VStack(alignment: .leading, spacing: LKSpacing.sm) {
            Text("YOUR WORKOUT PLANS")
                .font(LKFont.caption)
                .foregroundStyle(LKColors.Hex.textMuted)
                .tracking(2)
                .padding(.horizontal, LKSpacing.md)

            ForEach(visibleTemplates) { template in
                PlanCard(template: template) {
                    HapticManager.shared.buttonTap()
                    vm.startFromTemplate(template)
                    showActiveWorkout = true
                }
                .padding(.horizontal, LKSpacing.md)
            }

            if !atFreeLimit {
                addPlanButton
                    .padding(.horizontal, LKSpacing.md)
            } else {
                Text("Free accounts limited to 5 plans. Sign in for premium.")
                    .font(LKFont.caption)
                    .foregroundStyle(LKColors.Hex.textMuted)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, LKSpacing.md)
            }

            if isPremium && templates.count > UserProfile.maxVisibleTemplates {
                Button("View All Workout Plans") {
                    showAllTemplates = true
                }
                .font(LKFont.caption)
                .foregroundStyle(LKColors.Hex.accent)
                .frame(maxWidth: .infinity)
                .padding(.top, LKSpacing.xs)
                .sheet(isPresented: $showAllTemplates) {
                    AllTemplatesView(
                        onSelect: { template in
                            showAllTemplates = false
                            vm.startFromTemplate(template)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                showActiveWorkout = true
                            }
                        }
                    )
                }
            }
        }
    }

    private var addPlanButton: some View {
        Button {
            HapticManager.shared.buttonTap()
            showCreateWorkout = true
        } label: {
            HStack(spacing: LKSpacing.sm) {
                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(LKColors.Hex.accent)
                Text("Add New Workout Plan")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(LKColors.Hex.accent)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, LKSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: LKRadius.large)
                    .fill(LKColors.Hex.surfaceElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: LKRadius.large)
                            .strokeBorder(
                                LKColors.Hex.textMuted.opacity(0.4),
                                style: StrokeStyle(lineWidth: 1, dash: [6, 4])
                            )
                    )
            )
        }
        .accessibilityLabel("Add New Workout Plan")
    }
}

// MARK: - PlanCard

struct PlanCard: View {
    let template: WorkoutTemplate
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: LKSpacing.xs) {
                    Text(template.name)
                        .font(LKFont.bodyBold)
                        .foregroundStyle(LKColors.Hex.textPrimary)
                    Text("\(template.exercises.count) exercises")
                        .font(LKFont.caption)
                        .foregroundStyle(LKColors.Hex.textMuted)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: LKSpacing.xs) {
                    Text(template.lastUsedAt.map { relativeTime($0) } ?? "Never")
                        .font(.system(size: 12))
                        .foregroundStyle(LKColors.Hex.textSecondary)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(LKColors.Hex.textMuted)
                }
            }
            .padding(LKSpacing.md)
            .background(LKColors.Hex.surface)
            .clipShape(RoundedRectangle(cornerRadius: LKRadius.large))
            .overlay(
                RoundedRectangle(cornerRadius: LKRadius.large)
                    .strokeBorder(LKColors.Hex.surfaceElevated, lineWidth: 1)
            )
        }
        .accessibilityLabel("\(template.name), \(template.exercises.count) exercises — Double tap to start this workout")
    }

    private func relativeTime(_ date: Date) -> String {
        let diff = -date.timeIntervalSinceNow
        if diff < 3600       { return "\(Int(diff / 60)) min ago" }
        if diff < 86400      { return "\(Int(diff / 3600)) hours ago" }
        if diff < 86400 * 7  { return "\(Int(diff / 86400)) days ago" }
        return DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .none)
    }
}

// MARK: - AllTemplatesView

struct AllTemplatesView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \WorkoutTemplate.name) private var templates: [WorkoutTemplate]
    let onSelect: (WorkoutTemplate) -> Void

    @State private var search = ""
    @State private var filterType: TimerType? = nil

    private var filtered: [WorkoutTemplate] {
        templates.filter { t in
            (search.isEmpty || t.name.localizedCaseInsensitiveContains(search))
        }
    }

    var body: some View {
        NavigationStack {
            List(filtered) { template in
                Button {
                    onSelect(template)
                } label: {
                    VStack(alignment: .leading) {
                        Text(template.name).font(LKFont.bodyBold).foregroundStyle(LKColors.Hex.textPrimary)
                        Text("\(template.exercises.count) exercises").font(LKFont.caption).foregroundStyle(LKColors.Hex.textMuted)
                    }
                }
            }
            .searchable(text: $search, prompt: "Search plans")
            .navigationTitle("All Workout Plans")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundStyle(LKColors.Hex.textSecondary)
                }
            }
        }
    }
}
