import SwiftUI

struct WorkoutSetupView: View {
    @Environment(WorkoutViewModel.self) private var vm
    @Environment(\.dismiss) private var dismiss

    let onStart: () -> Void

    @State private var numberEntry: NumberEntryItem? = nil
    @State private var showSaveTemplate = false
    @State private var templateName = ""
    @State private var templateSaveError: String? = nil

    var body: some View {
        @Bindable var bvm = vm

        NavigationStack {
            ScrollView {
                VStack(spacing: LKSpacing.lg) {
                    typeHeader

                    nameSection(bvm: bvm)

                    typeSpecificControls(bvm: bvm)

                    notesSection(bvm: bvm)

                    startButton
                }
                .padding(.horizontal, LKSpacing.md)
                .padding(.vertical, LKSpacing.md)
            }
            .background(LKColors.Hex.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Back") { dismiss() }
                        .foregroundStyle(LKColors.Hex.danger)
                        .fontWeight(.semibold)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { showSaveTemplate = true }
                        .foregroundStyle(LKColors.Hex.accent)
                        .fontWeight(.semibold)
                }
            }
            .sheet(item: $numberEntry) { item in
                NumberEntrySheet(item: item)
            }
            .sheet(isPresented: $showSaveTemplate) {
                saveTemplateSheet
            }
        }
    }

    private var typeHeader: some View {
        VStack(spacing: LKSpacing.sm) {
            Image(systemName: vm.setupType.icon)
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(LKColors.Hex.accent)
            Text(vm.setupType.rawValue)
                .font(LKFont.title)
                .foregroundStyle(LKColors.Hex.textPrimary)
            Text(vm.setupType.subtitle)
                .font(LKFont.caption)
                .foregroundStyle(LKColors.Hex.textMuted)
                .multilineTextAlignment(.center)
        }
        .padding(.top, LKSpacing.sm)
    }

    private func nameSection(bvm: Bindable<WorkoutViewModel>) -> some View {
        VStack(alignment: .leading, spacing: LKSpacing.xs) {
            sectionLabel("WORKOUT NAME")
            TextField("e.g. Morning \(vm.setupType.rawValue)", text: bvm.setupName)
                .font(LKFont.body)
                .foregroundStyle(LKColors.Hex.textPrimary)
                .padding(LKSpacing.md)
                .background(LKColors.Hex.surface)
                .clipShape(RoundedRectangle(cornerRadius: LKRadius.medium))
        }
    }

    @ViewBuilder
    private func typeSpecificControls(bvm: Bindable<WorkoutViewModel>) -> some View {
        switch vm.setupType {
        case .amrap:
            amrapControls(bvm: bvm)
        case .emom:
            emomControls(bvm: bvm)
        case .forTime:
            forTimeControls(bvm: bvm)
        case .intervals:
            intervalsControls(bvm: bvm)
        case .reps:
            repsControls(bvm: bvm)
        case .manual:
            sessionsList(bvm: bvm)
        }
    }

    // MARK: - AMRAP

    private func amrapControls(bvm: Bindable<WorkoutViewModel>) -> some View {
        VStack(alignment: .leading, spacing: LKSpacing.md) {
            sectionLabel("TIME LIMIT")
            minutesSecondsRow(bvm: bvm)
            sessionsList(bvm: bvm)
        }
    }

    // MARK: - EMOM

    private func emomControls(bvm: Bindable<WorkoutViewModel>) -> some View {
        VStack(alignment: .leading, spacing: LKSpacing.md) {
            sectionLabel("TOTAL MINUTES")
            HStack(spacing: LKSpacing.md) {
                Button {
                    numberEntry = NumberEntryItem(title: "Minutes", min: 1, max: 120,
                                                  current: Double(vm.setupConfig.rounds)) { v in
                        bvm.setupConfig.wrappedValue.rounds = Int(v)
                    }
                } label: {
                    Text("\(vm.setupConfig.rounds)")
                        .font(LKFont.numeric)
                        .foregroundStyle(LKColors.Hex.accent)
                }
                Text("min").font(LKFont.body).foregroundStyle(LKColors.Hex.textSecondary)
                Spacer()
                stepperButtons(value: bvm.setupConfig.rounds, min: 1, max: 60) { bvm.setupConfig.wrappedValue.rounds = $0 }
            }
            .padding(LKSpacing.md)
            .background(LKColors.Hex.surface)
            .clipShape(RoundedRectangle(cornerRadius: LKRadius.medium))

            sectionLabel("WORKOUTS (cycle each minute)")
            sessionsList(bvm: bvm)
        }
    }

    // MARK: - For Time

    private func forTimeControls(bvm: Bindable<WorkoutViewModel>) -> some View {
        VStack(alignment: .leading, spacing: LKSpacing.md) {
            sectionLabel("TIME CAP")
            minutesSecondsRow(bvm: bvm)
            sessionsList(bvm: bvm)
        }
    }

    // MARK: - Intervals

    private func intervalsControls(bvm: Bindable<WorkoutViewModel>) -> some View {
        VStack(alignment: .leading, spacing: LKSpacing.md) {
            sectionLabel("WORK / REST / ROUNDS")
            VStack(spacing: LKSpacing.sm) {
                intervalRow(label: "WORK", value: bvm.setupConfig.workSeconds, min: 5, max: 300) { bvm.setupConfig.wrappedValue.workSeconds = $0 }
                Divider().background(LKColors.Hex.surfaceElevated)
                intervalRow(label: "REST", value: bvm.setupConfig.restSeconds, min: 5, max: 300) { bvm.setupConfig.wrappedValue.restSeconds = $0 }
                Divider().background(LKColors.Hex.surfaceElevated)
                intervalRow(label: "ROUNDS", value: bvm.setupConfig.rounds, min: 1, max: 50) { bvm.setupConfig.wrappedValue.rounds = $0 }
            }
            .padding(LKSpacing.md)
            .background(LKColors.Hex.surface)
            .clipShape(RoundedRectangle(cornerRadius: LKRadius.medium))

            sessionsList(bvm: bvm)
        }
    }

    private func intervalRow(label: String, value: Binding<Int>, min: Int, max: Int, set: @escaping (Int) -> Void) -> some View {
        HStack {
            Text(label)
                .font(LKFont.caption)
                .foregroundStyle(LKColors.Hex.textMuted)
                .tracking(1)
                .frame(width: 70, alignment: .leading)
            Button {
                numberEntry = NumberEntryItem(title: label.capitalized, min: Double(min), max: Double(max),
                                              current: Double(value.wrappedValue)) { v in set(Int(v)) }
            } label: {
                Text("\(value.wrappedValue)")
                    .font(LKFont.numeric)
                    .foregroundStyle(LKColors.Hex.accent)
            }
            Text("sec").font(LKFont.body).foregroundStyle(LKColors.Hex.textSecondary)
            Spacer()
            stepperButtons(value: value, min: min, max: max, set: set)
        }
    }

    // MARK: - Reps

    private func repsControls(bvm: Bindable<WorkoutViewModel>) -> some View {
        VStack(alignment: .leading, spacing: LKSpacing.md) {
            sectionLabel("REST BETWEEN SETS")
            HStack(spacing: LKSpacing.md) {
                Button {
                    numberEntry = NumberEntryItem(title: "Rest Seconds", min: 0, max: 300,
                                                  current: Double(vm.setupConfig.restBetweenSets)) { v in
                        bvm.setupConfig.wrappedValue.restBetweenSets = Int(v)
                    }
                } label: {
                    Text("\(vm.setupConfig.restBetweenSets)")
                        .font(LKFont.numeric)
                        .foregroundStyle(LKColors.Hex.accent)
                }
                Text("sec").font(LKFont.body).foregroundStyle(LKColors.Hex.textSecondary)
                Spacer()
                stepperButtons(value: bvm.setupConfig.restBetweenSets, min: 0, max: 300) { bvm.setupConfig.wrappedValue.restBetweenSets = $0 }
            }
            .padding(LKSpacing.md)
            .background(LKColors.Hex.surface)
            .clipShape(RoundedRectangle(cornerRadius: LKRadius.medium))

            sectionLabel("EXERCISES")
            exerciseList(bvm: bvm)
        }
    }

    // MARK: - Sessions list

    private func sessionsList(bvm: Bindable<WorkoutViewModel>) -> some View {
        VStack(alignment: .leading, spacing: LKSpacing.sm) {
            sectionLabel("WORKOUTS")
            ForEach(vm.setupSessions.indices, id: \.self) { i in
                SessionCard(
                    session: bvm.setupSessions[i],
                    canDelete: vm.setupSessions.count > 1,
                    onDelete: { bvm.setupSessions.wrappedValue.remove(at: i) },
                    onTapWeight: {
                        numberEntry = NumberEntryItem(title: "Weight", min: 0, max: 1000,
                                                      current: vm.setupSessions[i].weight) { v in
                            bvm.setupSessions.wrappedValue[i].weight = v
                        }
                    }
                )
            }
            dashedAddButton("+ Add Workout") {
                bvm.setupSessions.wrappedValue.append(SetupSession())
            }
        }
    }

    // MARK: - Exercise list

    private func exerciseList(bvm: Bindable<WorkoutViewModel>) -> some View {
        VStack(alignment: .leading, spacing: LKSpacing.sm) {
            ForEach(vm.setupExercises.indices, id: \.self) { i in
                ExerciseSetupCard(
                    exercise: bvm.setupExercises[i],
                    canDelete: vm.setupExercises.count > 1,
                    onDelete: { bvm.setupExercises.wrappedValue.remove(at: i) },
                    onTapWeight: {
                        numberEntry = NumberEntryItem(title: "Weight", min: 0, max: 1000,
                                                      current: vm.setupExercises[i].weight) { v in
                            bvm.setupExercises.wrappedValue[i].weight = v
                        }
                    },
                    onTapSets: {
                        numberEntry = NumberEntryItem(title: "Sets", min: 1, max: 20,
                                                      current: Double(vm.setupExercises[i].sets)) { v in
                            bvm.setupExercises.wrappedValue[i].sets = Int(v)
                        }
                    },
                    onTapReps: {
                        numberEntry = NumberEntryItem(title: "Reps", min: 1, max: 100,
                                                      current: Double(vm.setupExercises[i].reps)) { v in
                            bvm.setupExercises.wrappedValue[i].reps = Int(v)
                        }
                    }
                )
                .onChange(of: vm.setupExercises[i].name) { _, newVal in
                    if newVal.count >= 3 { vm.autoPopulateWeights() }
                }
            }
            if vm.setupExercises.count < 20 {
                dashedAddButton("+ Add Exercise") {
                    bvm.setupExercises.wrappedValue.append(SetupExercise())
                }
            }
        }
    }

    // MARK: - Notes

    private func notesSection(bvm: Bindable<WorkoutViewModel>) -> some View {
        VStack(alignment: .leading, spacing: LKSpacing.xs) {
            sectionLabel("NOTES")
            TextField("Optional notes...", text: bvm.setupNotes, axis: .vertical)
                .font(LKFont.body)
                .foregroundStyle(LKColors.Hex.textPrimary)
                .lineLimit(3...6)
                .padding(LKSpacing.md)
                .background(LKColors.Hex.surface)
                .clipShape(RoundedRectangle(cornerRadius: LKRadius.medium))
        }
    }

    // MARK: - Start button

    private var startButton: some View {
        Button {
            HapticManager.shared.buttonTap()
            vm.startWorkout()
            onStart()
        } label: {
            HStack(spacing: LKSpacing.sm) {
                Image(systemName: "play.fill")
                Text("Start \(vm.setupType.rawValue)")
            }
        }
        .buttonStyle(LKPrimaryButtonStyle())
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(LKFont.caption)
            .foregroundStyle(LKColors.Hex.textMuted)
            .tracking(1)
    }

    private func minutesSecondsRow(bvm: Bindable<WorkoutViewModel>) -> some View {
        VStack(spacing: LKSpacing.sm) {
            HStack(spacing: LKSpacing.md) {
                Button {
                    numberEntry = NumberEntryItem(title: "Minutes", min: 1, max: 120,
                                                  current: Double(vm.setupConfig.durationMinutes)) { v in
                        bvm.setupConfig.wrappedValue.durationMinutes = Int(v)
                    }
                } label: {
                    Text("\(vm.setupConfig.durationMinutes)")
                        .font(LKFont.numeric)
                        .foregroundStyle(LKColors.Hex.accent)
                }
                Text("min").font(LKFont.body).foregroundStyle(LKColors.Hex.textSecondary)
                Spacer()
                stepperButtons(value: bvm.setupConfig.durationMinutes, min: 0, max: 120) { bvm.setupConfig.wrappedValue.durationMinutes = $0 }
            }
            HStack(spacing: LKSpacing.md) {
                Button {
                    numberEntry = NumberEntryItem(title: "Seconds", min: 0, max: 55,
                                                  current: Double(vm.setupConfig.durationSeconds)) { v in
                        bvm.setupConfig.wrappedValue.durationSeconds = Int(v)
                    }
                } label: {
                    Text("\(vm.setupConfig.durationSeconds)")
                        .font(LKFont.numeric)
                        .foregroundStyle(LKColors.Hex.accent)
                }
                Text("sec").font(LKFont.body).foregroundStyle(LKColors.Hex.textSecondary)
                Spacer()
                stepperButtons(value: bvm.setupConfig.durationSeconds, min: 0, max: 55, step: 5) { bvm.setupConfig.wrappedValue.durationSeconds = $0 }
            }
        }
        .padding(LKSpacing.md)
        .background(LKColors.Hex.surface)
        .clipShape(RoundedRectangle(cornerRadius: LKRadius.medium))
    }

    private func stepperButtons(value: Binding<Int>, min: Int, max: Int, step: Int = 1, set: @escaping (Int) -> Void) -> some View {
        HStack(spacing: LKSpacing.sm) {
            Button {
                set(Swift.max(min, value.wrappedValue - step))
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(LKColors.Hex.textSecondary)
            }
            Button {
                set(Swift.min(max, value.wrappedValue + step))
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(LKColors.Hex.accent)
            }
        }
    }

    private func dashedAddButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: LKSpacing.xs) {
                Image(systemName: "plus").font(LKFont.caption)
                Text(label).font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(LKColors.Hex.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, LKSpacing.md)
            .overlay(
                RoundedRectangle(cornerRadius: LKRadius.medium)
                    .strokeBorder(LKColors.Hex.accent.opacity(0.5),
                                  style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
            )
        }
    }

    // MARK: - Save Template Sheet

    private var saveTemplateSheet: some View {
        NavigationStack {
            VStack(spacing: LKSpacing.lg) {
                VStack(spacing: LKSpacing.sm) {
                    Text("Save as Template")
                        .font(LKFont.heading)
                        .foregroundStyle(LKColors.Hex.textPrimary)

                    TextField("Template name", text: $templateName)
                        .font(LKFont.body)
                        .foregroundStyle(LKColors.Hex.textPrimary)
                        .padding(LKSpacing.md)
                        .background(LKColors.Hex.surface)
                        .clipShape(RoundedRectangle(cornerRadius: LKRadius.medium))
                        .overlay(
                            RoundedRectangle(cornerRadius: LKRadius.medium)
                                .strokeBorder(templateSaveError != nil ? LKColors.Hex.danger : Color.clear, lineWidth: 1)
                        )

                    if let err = templateSaveError {
                        Text(err)
                            .font(LKFont.caption)
                            .foregroundStyle(LKColors.Hex.danger)
                    }
                }
                .padding(LKSpacing.lg)

                Button("Save") {
                    if vm.saveAsTemplate(name: templateName) {
                        showSaveTemplate = false
                        templateName = ""
                    } else {
                        templateSaveError = vm.templateSaveError
                    }
                }
                .buttonStyle(LKPrimaryButtonStyle())
                .padding(.horizontal, LKSpacing.lg)
            }
            .background(LKColors.Hex.background)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        showSaveTemplate = false
                        templateSaveError = nil
                    }
                    .foregroundStyle(LKColors.Hex.textSecondary)
                }
            }
        }
    }
}

// MARK: - SessionCard

struct SessionCard: View {
    @Binding var session: SetupSession
    let canDelete: Bool
    let onDelete: () -> Void
    let onTapWeight: () -> Void

    var body: some View {
        VStack(spacing: LKSpacing.sm) {
            HStack {
                TextField("Workout name", text: $session.name)
                    .font(LKFont.bodyBold)
                    .foregroundStyle(LKColors.Hex.textPrimary)
                if canDelete {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundStyle(LKColors.Hex.danger)
                    }
                }
            }

            HStack(spacing: LKSpacing.sm) {
                Menu {
                    Button("None") { session.equipment = nil }
                    ForEach(Equipment.allCases, id: \.self) { eq in
                        Button(eq.rawValue) { session.equipment = eq }
                    }
                } label: {
                    HStack(spacing: LKSpacing.xs) {
                        if let eq = session.equipment {
                            Image(systemName: eq.icon)
                            Text(eq.rawValue)
                        } else {
                            Text("Equipment")
                        }
                        Image(systemName: "chevron.down")
                    }
                    .font(LKFont.caption)
                    .foregroundStyle(LKColors.Hex.textSecondary)
                    .padding(.horizontal, LKSpacing.sm)
                    .padding(.vertical, LKSpacing.xs)
                    .background(LKColors.Hex.surfaceElevated)
                    .clipShape(Capsule())
                }

                weightChip(weight: session.weight, unit: session.weightUnit, onTap: onTapWeight,
                           onMinus: { session.weight = max(0, session.weight - 5) },
                           onPlus: { session.weight = min(999, session.weight + 5) })
            }
        }
        .padding(LKSpacing.md)
        .background(LKColors.Hex.surface)
        .clipShape(RoundedRectangle(cornerRadius: LKRadius.large))
        .overlay(RoundedRectangle(cornerRadius: LKRadius.large)
            .strokeBorder(LKColors.Hex.surfaceElevated, lineWidth: 1))
    }
}

// MARK: - ExerciseSetupCard

struct ExerciseSetupCard: View {
    @Binding var exercise: SetupExercise
    let canDelete: Bool
    let onDelete: () -> Void
    let onTapWeight: () -> Void
    let onTapSets: () -> Void
    let onTapReps: () -> Void

    var body: some View {
        VStack(spacing: LKSpacing.sm) {
            HStack {
                TextField("Exercise name", text: $exercise.name)
                    .font(LKFont.bodyBold)
                    .foregroundStyle(LKColors.Hex.textPrimary)
                if canDelete {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundStyle(LKColors.Hex.danger)
                    }
                }
            }

            HStack(spacing: LKSpacing.sm) {
                Menu {
                    Button("None") { exercise.equipment = nil }
                    ForEach(Equipment.allCases, id: \.self) { eq in
                        Button(eq.rawValue) { exercise.equipment = eq }
                    }
                } label: {
                    HStack(spacing: LKSpacing.xs) {
                        if let eq = exercise.equipment {
                            Image(systemName: eq.icon)
                            Text(eq.rawValue)
                        } else {
                            Text("Equipment")
                        }
                        Image(systemName: "chevron.down")
                    }
                    .font(LKFont.caption)
                    .foregroundStyle(LKColors.Hex.textSecondary)
                    .padding(.horizontal, LKSpacing.sm)
                    .padding(.vertical, LKSpacing.xs)
                    .background(LKColors.Hex.surfaceElevated)
                    .clipShape(Capsule())
                }

                weightChip(weight: exercise.weight, unit: exercise.weightUnit, onTap: onTapWeight,
                           onMinus: { exercise.weight = max(0, exercise.weight - 5) },
                           onPlus: { exercise.weight = min(999, exercise.weight + 5) })
            }

            HStack(spacing: LKSpacing.lg) {
                HStack(spacing: LKSpacing.xs) {
                    Text("Sets").font(LKFont.caption).foregroundStyle(LKColors.Hex.textSecondary)
                    Button(action: onTapSets) {
                        Text("\(exercise.sets)")
                            .font(LKFont.numeric)
                            .foregroundStyle(LKColors.Hex.accent)
                    }
                    HStack(spacing: LKSpacing.xs) {
                        Button { exercise.sets = max(1, exercise.sets - 1) } label: {
                            Image(systemName: "minus.circle.fill").foregroundStyle(LKColors.Hex.textSecondary)
                        }
                        Button { exercise.sets = min(20, exercise.sets + 1) } label: {
                            Image(systemName: "plus.circle.fill").foregroundStyle(LKColors.Hex.accent)
                        }
                    }
                }

                HStack(spacing: LKSpacing.xs) {
                    Text("Reps").font(LKFont.caption).foregroundStyle(LKColors.Hex.textSecondary)
                    Button(action: onTapReps) {
                        Text("\(exercise.reps)")
                            .font(LKFont.numeric)
                            .foregroundStyle(LKColors.Hex.accent)
                    }
                    HStack(spacing: LKSpacing.xs) {
                        Button { exercise.reps = max(1, exercise.reps - 1) } label: {
                            Image(systemName: "minus.circle.fill").foregroundStyle(LKColors.Hex.textSecondary)
                        }
                        Button { exercise.reps = min(100, exercise.reps + 1) } label: {
                            Image(systemName: "plus.circle.fill").foregroundStyle(LKColors.Hex.accent)
                        }
                    }
                }
            }
        }
        .padding(LKSpacing.md)
        .background(LKColors.Hex.surface)
        .clipShape(RoundedRectangle(cornerRadius: LKRadius.large))
        .overlay(RoundedRectangle(cornerRadius: LKRadius.large)
            .strokeBorder(LKColors.Hex.surfaceElevated, lineWidth: 1))
    }
}

// MARK: - Weight Chip helper

func weightChip(weight: Double, unit: WeightUnit, onTap: @escaping () -> Void,
                onMinus: @escaping () -> Void, onPlus: @escaping () -> Void) -> some View {
    HStack(spacing: 0) {
        Button(action: onMinus) {
            Text("−5").font(LKFont.caption).foregroundStyle(LKColors.Hex.textSecondary)
                .padding(.horizontal, LKSpacing.sm)
        }
        Button(action: onTap) {
            Text("\(Int(weight)) \(unit.rawValue)")
                .font(LKFont.caption)
                .foregroundStyle(LKColors.Hex.accent)
                .underline()
        }
        Button(action: onPlus) {
            Text("+5").font(LKFont.caption).foregroundStyle(LKColors.Hex.textSecondary)
                .padding(.horizontal, LKSpacing.sm)
        }
    }
    .padding(.horizontal, LKSpacing.xs)
    .padding(.vertical, LKSpacing.xs)
    .background(LKColors.Hex.surfaceElevated)
    .clipShape(Capsule())
}
