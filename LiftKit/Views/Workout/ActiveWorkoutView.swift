import SwiftUI

struct ActiveWorkoutView: View {
    @Environment(WorkoutViewModel.self) private var vm
    @Environment(\.dismiss) private var dismiss

    @State private var showEndConfirmation = false
    @State private var showSaveTemplate = false
    @State private var templateName = ""
    @State private var templateError: String? = nil
    @State private var soundEnabled = true
    @State private var numberEntry: NumberEntryItem? = nil

    private var currentSession: LiveExercise? {
        guard vm.currentSessionIndex < vm.liveExercises.count else { return nil }
        return vm.liveExercises[vm.currentSessionIndex]
    }

    private var isOverCap: Bool {
        vm.setupType == .forTime && vm.mainTimer.phase == .work &&
        vm.mainTimer.elapsedTime > Double(vm.setupConfig.totalDurationSeconds)
    }

    private var bgColor: Color {
        switch vm.mainTimer.phase {
        case .rest: return LKColors.Hex.rest.opacity(0.1)
        default:    return isOverCap ? LKColors.Hex.danger.opacity(0.15) : LKColors.Hex.background
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                bgColor.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: LKSpacing.lg) {
                        typeSpecificContent
                        notesDisplay
                    }
                    .padding(.horizontal, LKSpacing.md)
                    .padding(.top, LKSpacing.md)
                    .padding(.bottom, LKSpacing.xxl)
                }

                completionOverlay

                VStack {
                    ForEach(vm.prBanners) { banner in
                        PRBannerView(types: banner.types)
                            .transition(.move(edge: .top))
                    }
                    Spacer()
                }
                .animation(.easeInOut, value: vm.prBanners.count)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .confirmationDialog("End Workout?", isPresented: $showEndConfirmation) {
                Button("Save & End") {
                    vm.saveAndEnd()
                }
                Button("Discard", role: .destructive) {
                    vm.discardWorkout()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(item: $numberEntry) { item in
                NumberEntrySheet(item: item)
            }
            .sheet(isPresented: $showSaveTemplate) {
                saveTemplateSheet
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("End") {
                showEndConfirmation = true
            }
            .font(.system(size: 17, weight: .bold))
            .foregroundStyle(LKColors.Hex.danger)
        }
        ToolbarItem(placement: .principal) {
            Text(vm.activeSession?.name ?? vm.setupType.rawValue)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(LKColors.Hex.textPrimary)
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
                showSaveTemplate = true
            } label: {
                Image(systemName: "square.and.arrow.down")
                    .foregroundStyle(LKColors.Hex.textSecondary)
            }
            Button {
                soundEnabled.toggle()
            } label: {
                Image(systemName: soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    .foregroundStyle(LKColors.Hex.textSecondary)
            }
        }
    }

    // MARK: - Type-specific content

    @ViewBuilder
    private var typeSpecificContent: some View {
        switch vm.setupType {
        case .amrap:     AMRAPActiveView(numberEntry: $numberEntry)
        case .emom:      EMOMActiveView()
        case .forTime:   ForTimeActiveView(numberEntry: $numberEntry)
        case .intervals: IntervalsActiveView()
        case .reps:      RepsActiveView(numberEntry: $numberEntry)
        case .manual:    ManualActiveView()
        }
    }

    // MARK: - Notes

    @ViewBuilder
    private var notesDisplay: some View {
        if let notes = vm.activeSession?.notes, !notes.isEmpty {
            Text(notes)
                .font(LKFont.body)
                .foregroundStyle(LKColors.Hex.textSecondary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(LKSpacing.md)
                .background(LKColors.Hex.surface)
                .clipShape(RoundedRectangle(cornerRadius: LKRadius.small))
        }
    }

    // MARK: - Completion overlay

    @ViewBuilder
    private var completionOverlay: some View {
        if !vm.isWorkoutActive && !vm.completionMessage.isEmpty {
            ZStack {
                Color.black.opacity(0.7).ignoresSafeArea()
                    .onTapGesture {
                        vm.dismissWorkout()
                        dismiss()
                    }

                VStack(spacing: LKSpacing.lg) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(LKColors.Hex.accent)

                    Text("Workout Complete!")
                        .font(LKFont.title)
                        .foregroundStyle(LKColors.Hex.textPrimary)

                    if vm.setupType == .amrap {
                        Text("\(vm.amrapRounds) rounds")
                            .font(LKFont.heading)
                            .foregroundStyle(LKColors.Hex.accent)
                    }

                    Text(vm.completionMessage)
                        .font(LKFont.body)
                        .foregroundStyle(LKColors.Hex.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, LKSpacing.lg)

                    Button("End Workout") {
                        vm.dismissWorkout()
                        dismiss()
                    }
                    .buttonStyle(LKPrimaryButtonStyle())
                    .padding(.horizontal, LKSpacing.lg)

                    Button("Go Back") {
                        vm.completionMessage = ""
                    }
                    .font(LKFont.body)
                    .foregroundStyle(LKColors.Hex.textSecondary)

                    Text("Tap anywhere to dismiss")
                        .font(LKFont.caption)
                        .foregroundStyle(LKColors.Hex.textMuted)
                }
                .padding(LKSpacing.xl)
                .background(LKColors.Hex.surface)
                .clipShape(RoundedRectangle(cornerRadius: LKRadius.large))
                .padding(LKSpacing.xl)
            }
        }
    }

    // MARK: - Save template sheet

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
                        .overlay(RoundedRectangle(cornerRadius: LKRadius.medium)
                            .strokeBorder(templateError != nil ? LKColors.Hex.danger : Color.clear, lineWidth: 1))
                    if let err = templateError {
                        Text(err).font(LKFont.caption).foregroundStyle(LKColors.Hex.danger)
                    }
                }
                .padding(LKSpacing.lg)

                Button("Save") {
                    if vm.saveAsTemplate(name: templateName) {
                        showSaveTemplate = false
                        templateName = ""
                        templateError = nil
                    } else {
                        templateError = vm.templateSaveError
                    }
                }
                .buttonStyle(LKPrimaryButtonStyle())
                .padding(.horizontal, LKSpacing.lg)
            }
            .background(LKColors.Hex.background)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { showSaveTemplate = false }
                        .foregroundStyle(LKColors.Hex.textSecondary)
                }
            }
        }
    }
}

// MARK: - PR Banner

struct PRBannerView: View {
    let types: [PRType]

    var body: some View {
        HStack(spacing: LKSpacing.sm) {
            Image(systemName: "trophy.fill").foregroundStyle(Color.yellow)
            Text("New PR! \(types.map(\.label).joined(separator: ", "))")
                .font(LKFont.bodyBold)
                .foregroundStyle(LKColors.Hex.textPrimary)
            Image(systemName: "trophy.fill").foregroundStyle(Color.yellow)
        }
        .padding(LKSpacing.md)
        .background(.ultraThickMaterial)
        .clipShape(RoundedRectangle(cornerRadius: LKRadius.large))
        .shadow(radius: 8)
        .padding(.horizontal, LKSpacing.md)
        .padding(.top, LKSpacing.md)
    }
}

// MARK: - Timer Controls

struct TimerControls: View {
    @Environment(WorkoutViewModel.self) private var vm

    var body: some View {
        HStack(spacing: LKSpacing.xl) {
            CircleButton(icon: "forward.fill", size: 60, bgColor: LKColors.Hex.surfaceElevated,
                         iconColor: LKColors.Hex.textSecondary) {
                vm.mainTimer.skip()
            }
            CircleButton(icon: vm.mainTimer.isRunning ? "pause.fill" : "play.fill",
                         size: 88, bgColor: LKColors.Hex.accent, iconColor: LKColors.Hex.background) {
                if vm.mainTimer.isRunning { vm.mainTimer.pause() }
                else { vm.mainTimer.resume() }
            }
            CircleButton(icon: "stop.fill", size: 60, bgColor: LKColors.Hex.surfaceElevated,
                         iconColor: LKColors.Hex.danger) {
                vm.finishWorkout()
            }
        }
    }
}

struct CircleButton: View {
    let icon: String
    let size: CGFloat
    let bgColor: Color
    let iconColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: { HapticManager.shared.buttonTap(); action() }) {
            Image(systemName: icon)
                .font(.system(size: size * 0.35, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: size, height: size)
                .background(bgColor)
                .clipShape(Circle())
        }
    }
}

// MARK: - AMRAP Active

struct AMRAPActiveView: View {
    @Environment(WorkoutViewModel.self) private var vm
    @Binding var numberEntry: NumberEntryItem?

    var body: some View {
        VStack(spacing: LKSpacing.lg) {
            if vm.liveExercises.count > 1 {
                Text("Workout \(vm.currentSessionIndex + 1) of \(vm.liveExercises.count)")
                    .font(LKFont.body)
                    .foregroundStyle(LKColors.Hex.textSecondary)
            }
            phaseLabel(vm.mainTimer.phase)
            TimerDisplayView(timeString: vm.mainTimer.formattedTime)
            if let ex = vm.liveExercises[safe: vm.currentSessionIndex] {
                activeWeightChips(exercise: ex, index: vm.currentSessionIndex)
            }
            roundsCounter
            TimerControls()
        }
    }

    private var roundsCounter: some View {
        VStack(spacing: LKSpacing.xs) {
            Text("ROUNDS COMPLETED")
                .font(LKFont.caption)
                .foregroundStyle(LKColors.Hex.textMuted)
                .tracking(1)
            HStack(spacing: LKSpacing.lg) {
                Button { vm.adjustRounds(delta: -1) } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title)
                        .foregroundStyle(LKColors.Hex.textSecondary)
                }
                Button {
                    numberEntry = NumberEntryItem(title: "Rounds Completed", min: 0, max: 999,
                                                  current: Double(vm.amrapRounds)) { v in
                        vm.setRounds(Int(v))
                    }
                } label: {
                    Text("\(vm.amrapRounds)")
                        .font(LKFont.timer(56))
                        .foregroundStyle(LKColors.Hex.accent)
                }
                Button { vm.adjustRounds(delta: 1) } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundStyle(LKColors.Hex.accent)
                }
            }
        }
    }
}

// MARK: - EMOM Active

struct EMOMActiveView: View {
    @Environment(WorkoutViewModel.self) private var vm

    var body: some View {
        VStack(spacing: LKSpacing.lg) {
            if let ex = vm.liveExercises[safe: vm.mainTimer.currentRound - 1] {
                Text(ex.name)
                    .font(LKFont.heading)
                    .foregroundStyle(LKColors.Hex.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            phaseLabel(vm.mainTimer.phase)
            TimerDisplayView(timeString: vm.mainTimer.formattedTime)
            Text("Minute \(vm.mainTimer.currentRound) of \(vm.mainTimer.totalRounds)")
                .font(LKFont.body)
                .foregroundStyle(LKColors.Hex.textSecondary)
            if let ex = vm.liveExercises[safe: vm.mainTimer.currentRound - 1] {
                activeWeightChips(exercise: ex, index: vm.mainTimer.currentRound - 1)
            }
            TimerControls()
            if vm.liveExercises.count > 1,
               let next = vm.liveExercises[safe: vm.mainTimer.currentRound % vm.liveExercises.count] {
                VStack(spacing: LKSpacing.xs) {
                    Text("UP NEXT")
                        .font(LKFont.caption)
                        .foregroundStyle(LKColors.Hex.textMuted)
                        .tracking(1)
                    Text(next.name)
                        .font(LKFont.body)
                        .foregroundStyle(LKColors.Hex.textSecondary)
                }
            }
        }
    }
}

// MARK: - For Time Active

struct ForTimeActiveView: View {
    @Environment(WorkoutViewModel.self) private var vm
    @Binding var numberEntry: NumberEntryItem?
    private var isOverCap: Bool {
        vm.mainTimer.elapsedTime > Double(vm.setupConfig.totalDurationSeconds)
    }

    var body: some View {
        VStack(spacing: LKSpacing.lg) {
            if vm.liveExercises.count > 1 {
                Text("Workout \(vm.currentSessionIndex + 1) of \(vm.liveExercises.count)")
                    .font(LKFont.body).foregroundStyle(LKColors.Hex.textSecondary)
            }
            if isOverCap {
                Text("TIME CAP")
                    .font(LKFont.phase)
                    .foregroundStyle(LKColors.Hex.danger)
                    .tracking(4)
            } else {
                phaseLabel(vm.mainTimer.phase)
            }
            TimerDisplayView(timeString: vm.mainTimer.formatTime(vm.mainTimer.elapsedTime),
                             color: isOverCap ? LKColors.Hex.danger : LKColors.Hex.textPrimary)
            Text("Cap: \(vm.mainTimer.formatTime(Double(vm.setupConfig.totalDurationSeconds)))")
                .font(LKFont.caption)
                .foregroundStyle(LKColors.Hex.textMuted)
            if let ex = vm.liveExercises[safe: vm.currentSessionIndex] {
                activeWeightChips(exercise: ex, index: vm.currentSessionIndex)
            }
            Button {
                vm.markForTimeComplete()
            } label: {
                HStack(spacing: LKSpacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Mark Complete")
                }
            }
            .buttonStyle(LKSecondaryButtonStyle())
            .tint(LKColors.Hex.work)
            TimerControls()
        }
    }

    private var currentSessionIndex: Int { vm.currentSessionIndex }
}

// MARK: - Intervals Active

struct IntervalsActiveView: View {
    @Environment(WorkoutViewModel.self) private var vm

    var body: some View {
        VStack(spacing: LKSpacing.lg) {
            if vm.liveExercises.count > 1 {
                Text("Workout \(vm.currentSessionIndex + 1) of \(vm.liveExercises.count)")
                    .font(LKFont.body).foregroundStyle(LKColors.Hex.textSecondary)
            }
            phaseLabel(vm.mainTimer.phase)
            TimerDisplayView(timeString: vm.mainTimer.formattedTime)
            Text("Round \(vm.mainTimer.currentRound) of \(vm.mainTimer.totalRounds)")
                .font(LKFont.body)
                .foregroundStyle(LKColors.Hex.textSecondary)
            if let ex = vm.liveExercises[safe: vm.currentSessionIndex] {
                activeWeightChips(exercise: ex, index: vm.currentSessionIndex)
            }
            TimerControls()
        }
    }
}

// MARK: - Reps Active

struct RepsActiveView: View {
    @Environment(WorkoutViewModel.self) private var vm
    @Binding var numberEntry: NumberEntryItem?

    var body: some View {
        VStack(spacing: LKSpacing.lg) {
            restBanner
            exerciseCards
        }
    }

    @ViewBuilder
    private var restBanner: some View {
        if case .rest = vm.restTimer.phase {
            VStack(spacing: LKSpacing.xs) {
                Text("REST")
                    .font(LKFont.phase)
                    .foregroundStyle(LKColors.Hex.rest)
                    .tracking(4)
                TimerDisplayView(timeString: vm.restTimer.formattedTime, size: 48)
                Button("Skip") { vm.skipRest() }
                    .font(LKFont.bodyBold)
                    .foregroundStyle(LKColors.Hex.accent)
            }
            .padding(LKSpacing.md)
            .background(LKColors.Hex.rest.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: LKRadius.large))
        } else if case .complete = vm.restTimer.phase {
            VStack(spacing: LKSpacing.xs) {
                Text("GO")
                    .font(LKFont.phase)
                    .foregroundStyle(LKColors.Hex.work)
                    .tracking(4)
                Button("Skip") { vm.skipRest() }
                    .font(LKFont.bodyBold)
                    .foregroundStyle(LKColors.Hex.accent)
            }
            .padding(LKSpacing.md)
            .background(LKColors.Hex.work.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: LKRadius.large))
        }
    }

    private var exerciseCards: some View {
        ForEach(vm.liveExercises.indices, id: \.self) { i in
            let ex = vm.liveExercises[i]
            VStack(spacing: LKSpacing.md) {
                HStack {
                    Text(ex.name)
                        .font(LKFont.heading)
                        .foregroundStyle(LKColors.Hex.textPrimary)
                    Spacer()
                }
                HStack(spacing: LKSpacing.sm) {
                    if let eq = ex.equipment {
                        HStack(spacing: LKSpacing.xs) {
                            Image(systemName: eq.icon)
                            Text(eq.rawValue)
                        }
                        .font(LKFont.caption)
                        .foregroundStyle(LKColors.Hex.textSecondary)
                        .padding(.horizontal, LKSpacing.sm)
                        .padding(.vertical, LKSpacing.xs)
                        .background(LKColors.Hex.surfaceElevated)
                        .clipShape(Capsule())
                    }
                    activeWeightChips(exercise: ex, index: i)
                }
                setCircles(exerciseIndex: i, exercise: ex)
            }
            .padding(LKSpacing.md)
            .background(LKColors.Hex.surface)
            .clipShape(RoundedRectangle(cornerRadius: LKRadius.large))
        }
    }

    private func setCircles(exerciseIndex: Int, exercise: LiveExercise) -> some View {
        HStack(spacing: LKSpacing.sm) {
            ForEach(0..<exercise.plannedSets, id: \.self) { setIdx in
                let done = exercise.isCompleted[setIdx]
                let reps = exercise.completedReps[setIdx] ?? exercise.plannedReps
                Button {
                    if done {
                        numberEntry = NumberEntryItem(title: "Reps", min: 0, max: 100,
                                                      current: Double(reps)) { v in
                            vm.setActualReps(exerciseIndex: exerciseIndex, setIndex: setIdx, reps: Int(v))
                        }
                    } else {
                        vm.completeSet(exerciseIndex: exerciseIndex, setIndex: setIdx)
                    }
                } label: {
                    Text("\(reps)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(done ? Color.white : LKColors.Hex.textPrimary)
                        .frame(width: 48, height: 48)
                        .background(done ? LKColors.Hex.success : LKColors.Hex.surfaceElevated)
                        .clipShape(Circle())
                }
            }
        }
    }
}

// MARK: - Manual Active

struct ManualActiveView: View {
    @Environment(WorkoutViewModel.self) private var vm

    var body: some View {
        VStack(spacing: LKSpacing.lg) {
            if let ex = vm.liveExercises.first, !ex.name.isEmpty {
                Text(ex.name)
                    .font(LKFont.heading)
                    .foregroundStyle(LKColors.Hex.textPrimary)
            }
            TimerDisplayView(timeString: vm.mainTimer.formatTime(vm.mainTimer.elapsedTime))
            if let ex = vm.liveExercises[safe: vm.currentSessionIndex] {
                activeWeightChips(exercise: ex, index: vm.currentSessionIndex)
            }
            CircleButton(icon: vm.mainTimer.isRunning ? "pause.fill" : "play.fill",
                         size: 88, bgColor: LKColors.Hex.accent, iconColor: LKColors.Hex.background) {
                if vm.mainTimer.isRunning { vm.mainTimer.pause() }
                else { vm.mainTimer.resume() }
            }
            if vm.liveExercises.count > 1 {
                Button {
                    vm.advanceSession()
                } label: {
                    HStack(spacing: LKSpacing.xs) {
                        Image(systemName: "forward.fill")
                        Text("Next")
                    }
                }
                .frame(width: 60, height: 60)
                .background(LKColors.Hex.surfaceElevated)
                .clipShape(Circle())
                .foregroundStyle(LKColors.Hex.textSecondary)
            }
        }
    }
}

// MARK: - Shared helpers

private func phaseLabel(_ phase: TimerPhase) -> some View {
    let (text, color): (String, Color) = {
        switch phase {
        case .work:            return ("WORK", LKColors.Hex.work)
        case .rest:            return ("REST", LKColors.Hex.rest)
        case .complete:        return ("Done", LKColors.Hex.accent)
        case .idle:            return ("Ready", LKColors.Hex.textSecondary)
        case .countdown(let n): return ("\(n)", LKColors.Hex.textSecondary)
        }
    }()
    return Text(text)
        .font(LKFont.phase)
        .foregroundStyle(color)
        .tracking(4)
}

private func activeWeightChips(exercise: LiveExercise, index: Int) -> some View {
    ActiveWeightChipView(exercise: exercise, index: index)
}

struct ActiveWeightChipView: View {
    @Environment(WorkoutViewModel.self) private var vm
    let exercise: LiveExercise
    let index: Int
    @State private var numberEntry: NumberEntryItem? = nil

    var body: some View {
        HStack(spacing: LKSpacing.sm) {
            if let eq = exercise.equipment {
                HStack(spacing: LKSpacing.xs) {
                    Image(systemName: eq.icon)
                    Text(eq.rawValue)
                }
                .font(LKFont.caption)
                .foregroundStyle(LKColors.Hex.textSecondary)
            }
            HStack(spacing: 0) {
                Button { vm.adjustWeight(index: index, delta: -5) } label: {
                    Text("−5").font(LKFont.caption).foregroundStyle(LKColors.Hex.textSecondary)
                        .padding(.horizontal, LKSpacing.sm)
                }
                Button {
                    numberEntry = NumberEntryItem(title: "Weight", min: 0, max: 1000,
                                                  current: exercise.weight) { v in
                        vm.setWeight(index: index, weight: v)
                    }
                } label: {
                    Text("\(Int(exercise.weight)) \(exercise.weightUnit.rawValue)")
                        .font(LKFont.caption)
                        .foregroundStyle(LKColors.Hex.accent)
                        .underline()
                }
                Button { vm.adjustWeight(index: index, delta: 5) } label: {
                    Text("+5").font(LKFont.caption).foregroundStyle(LKColors.Hex.textSecondary)
                        .padding(.horizontal, LKSpacing.sm)
                }
            }
            .padding(.horizontal, LKSpacing.xs)
            .padding(.vertical, LKSpacing.xs)
            .background(LKColors.Hex.surfaceElevated)
            .clipShape(Capsule())
        }
        .sheet(item: $numberEntry) { item in
            NumberEntrySheet(item: item)
        }
    }
}

// MARK: - Array safe subscript

extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
}
