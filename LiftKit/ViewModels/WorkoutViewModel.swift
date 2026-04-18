import Foundation
import SwiftData

// MARK: - Setup Exercise (used in setup screen)

struct SetupExercise: Identifiable {
    var id = UUID()
    var name: String = ""
    var equipment: Equipment? = nil
    var weight: Double = 0
    var weightUnit: WeightUnit = .lb
    var sets: Int = 3
    var reps: Int = 10
}

// MARK: - Setup Session (used for AMRAP/EMOM/ForTime/Intervals/Manual sessions)

struct SetupSession: Identifiable {
    var id = UUID()
    var name: String = ""
    var equipment: Equipment? = nil
    var weight: Double = 0
    var weightUnit: WeightUnit = .lb
}

// MARK: - Live Exercise (active workout)

struct LiveExercise: Identifiable {
    var id = UUID()
    var name: String
    var equipment: Equipment?
    var weight: Double
    var weightUnit: WeightUnit
    var plannedSets: Int
    var plannedReps: Int
    var completedReps: [Int?]
    var isCompleted: [Bool]

    var completedCount: Int { isCompleted.filter { $0 }.count }
    var allComplete: Bool { isCompleted.allSatisfy { $0 } }
}

// MARK: - PR Banner

struct PRBanner: Identifiable {
    let id = UUID()
    let types: [PRType]
}

// MARK: - WorkoutViewModel

@Observable
final class WorkoutViewModel {
    // Setup state
    var setupType: TimerType = .amrap
    var setupConfig: TimerConfig = .defaultConfig(for: .amrap)
    var setupSessions: [SetupSession] = [SetupSession()]
    var setupExercises: [SetupExercise] = [SetupExercise()]
    var setupName: String = ""
    var setupNotes: String = ""

    // Active state
    private(set) var activeSession: WorkoutSession?
    private(set) var currentSessionIndex: Int = 0
    private(set) var liveExercises: [LiveExercise] = []
    private(set) var amrapRounds: Int = 0
    private(set) var isWorkoutActive: Bool = false
    private(set) var completionMessage: String = ""
    private(set) var prBanners: [PRBanner] = []
    private(set) var templateSaveError: String? = nil

    // Timer engines
    let mainTimer = TimerEngine(notificationPrefix: "main")
    let restTimer = TimerEngine(notificationPrefix: "rest")

    // Services
    private var modelContext: ModelContext?
    private var prService: PRDetectionService?
    private var weightCache: WeightCache?

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.prService    = PRDetectionService(modelContext: modelContext)
        self.weightCache  = WeightCache(modelContext: modelContext)

        mainTimer.onComplete = { [weak self] in
            DispatchQueue.main.async { self?.handleMainTimerComplete() }
        }
        restTimer.onComplete = { [weak self] in
            DispatchQueue.main.async { self?.handleRestTimerComplete() }
        }
    }

    // MARK: - Setup helpers

    func resetSetup(for type: TimerType) {
        setupType    = type
        setupConfig  = .defaultConfig(for: type)
        setupSessions = [SetupSession()]
        setupExercises = [SetupExercise()]
        setupName    = ""
        setupNotes   = ""
    }

    func autoPopulateWeights() {
        guard let cache = weightCache else { return }
        for i in setupExercises.indices {
            let name = setupExercises[i].name
            guard name.count >= 3 else { continue }
            if let cached = cache.lookup(exerciseName: name) {
                setupExercises[i].weight     = cached.weight
                setupExercises[i].weightUnit = cached.unit
                if setupExercises[i].equipment == nil {
                    setupExercises[i].equipment = cached.equipment
                }
            }
        }
        for i in setupSessions.indices {
            let name = setupSessions[i].name
            guard name.count >= 3 else { continue }
            if let cached = cache.lookup(exerciseName: name) {
                setupSessions[i].weight     = cached.weight
                setupSessions[i].weightUnit = cached.unit
                if setupSessions[i].equipment == nil {
                    setupSessions[i].equipment = cached.equipment
                }
            }
        }
    }

    // MARK: - Start workout

    func startWorkout() {
        guard let ctx = modelContext else { return }
        let name = setupName.trimmingCharacters(in: .whitespacesAndNewlines)
        let sessionName = name.isEmpty ? setupType.rawValue : name

        let session = WorkoutSession(name: sessionName, notes: setupNotes.isEmpty ? nil : setupNotes,
                                     workoutType: setupType.rawValue)
        ctx.insert(session)

        switch setupType {
        case .reps:
            var live: [LiveExercise] = []
            for ex in setupExercises {
                let exerciseObj = findOrCreateExercise(name: ex.name, equipment: ex.equipment, in: ctx)
                let entry = WorkoutEntry(exercise: exerciseObj, session: session,
                                        timerType: .reps, sortOrder: live.count)
                ctx.insert(entry)
                let liveEx = LiveExercise(
                    name: ex.name.isEmpty ? "Exercise" : ex.name,
                    equipment: ex.equipment,
                    weight: ex.weight,
                    weightUnit: ex.weightUnit,
                    plannedSets: ex.sets,
                    plannedReps: ex.reps,
                    completedReps: Array(repeating: nil, count: ex.sets),
                    isCompleted: Array(repeating: false, count: ex.sets)
                )
                live.append(liveEx)
            }
            liveExercises = live

        default:
            for (i, ss) in setupSessions.enumerated() {
                let exName = ss.name.isEmpty ? setupType.rawValue : ss.name
                let exerciseObj = findOrCreateExercise(name: exName, equipment: ss.equipment, in: ctx)
                let entry = WorkoutEntry(exercise: exerciseObj, session: session,
                                        timerType: setupType, sortOrder: i)
                ctx.insert(entry)
            }
            liveExercises = setupSessions.enumerated().map { i, ss in
                LiveExercise(
                    name: ss.name.isEmpty ? setupType.rawValue : ss.name,
                    equipment: ss.equipment,
                    weight: ss.weight,
                    weightUnit: ss.weightUnit,
                    plannedSets: 1,
                    plannedReps: 1,
                    completedReps: [],
                    isCompleted: []
                )
            }
        }

        try? ctx.save()

        activeSession      = session
        currentSessionIndex = 0
        amrapRounds        = 0
        isWorkoutActive    = true
        completionMessage  = ""
        prBanners          = []

        if setupType != .reps {
            mainTimer.start(config: setupConfig)
        }
    }

    func startFromTemplate(_ template: WorkoutTemplate) {
        guard let ctx = modelContext else { return }
        template.lastUsedAt = Date()

        setupType    = template.exercises.first?.timerType ?? .reps
        setupName    = template.name
        setupConfig  = template.exercises.first?.timerConfig ?? .defaultConfig(for: setupType)
        setupExercises = template.exercises.sorted { $0.sortOrder < $1.sortOrder }.map { te in
            var ex = SetupExercise()
            ex.name      = te.exercise?.name ?? ""
            ex.equipment = te.exercise?.equipment
            ex.sets      = te.targetSets
            ex.reps      = te.targetReps
            return ex
        }
        setupSessions = template.exercises.sorted { $0.sortOrder < $1.sortOrder }.map { te in
            var ss = SetupSession()
            ss.name      = te.exercise?.name ?? ""
            ss.equipment = te.exercise?.equipment
            return ss
        }
        autoPopulateWeights()
        startWorkout()

        try? ctx.save()
    }

    func repeatWorkout(_ session: WorkoutSession) {
        guard let ctx = modelContext else { return }

        setupType  = session.timerType ?? .reps
        setupName  = session.name
        setupNotes = session.notes ?? ""
        setupConfig = .defaultConfig(for: setupType)

        let sortedEntries = session.entries.sorted { $0.sortOrder < $1.sortOrder }
        setupExercises = sortedEntries.map { entry in
            var ex = SetupExercise()
            ex.name      = entry.exercise?.name ?? ""
            ex.equipment = entry.exercise?.equipment
            if let best = entry.bestSet {
                ex.weight = best.weight ?? 0
                ex.reps   = best.reps ?? 10
            }
            return ex
        }
        setupSessions = sortedEntries.map { entry in
            var ss = SetupSession()
            ss.name      = entry.exercise?.name ?? ""
            ss.equipment = entry.exercise?.equipment
            if let best = entry.bestSet {
                ss.weight = best.weight ?? 0
            }
            return ss
        }
        autoPopulateWeights()
        startWorkout()
        _ = ctx
    }

    // MARK: - Active workout actions

    func completeSet(exerciseIndex: Int, setIndex: Int) {
        guard exerciseIndex < liveExercises.count else { return }
        guard setIndex < liveExercises[exerciseIndex].plannedSets else { return }

        liveExercises[exerciseIndex].isCompleted[setIndex] = true
        let reps = liveExercises[exerciseIndex].completedReps[setIndex]
            ?? liveExercises[exerciseIndex].plannedReps
        liveExercises[exerciseIndex].completedReps[setIndex] = reps

        HapticManager.shared.setLogged()
        persistSet(exerciseIndex: exerciseIndex, setIndex: setIndex, reps: reps)

        // Start rest timer
        let restDuration = Double(setupConfig.restBetweenSets > 0 ? setupConfig.restBetweenSets : 90)
        restTimer.start(config: setupConfig)
        restTimer.startRestTimer(restDuration)
    }

    func uncompleteSet(exerciseIndex: Int, setIndex: Int) {
        guard exerciseIndex < liveExercises.count,
              setIndex < liveExercises[exerciseIndex].plannedSets else { return }
        liveExercises[exerciseIndex].isCompleted[setIndex] = false
        liveExercises[exerciseIndex].completedReps[setIndex] = nil
    }

    func setActualReps(exerciseIndex: Int, setIndex: Int, reps: Int) {
        guard exerciseIndex < liveExercises.count,
              setIndex < liveExercises[exerciseIndex].plannedSets else { return }
        if reps <= 0 {
            uncompleteSet(exerciseIndex: exerciseIndex, setIndex: setIndex)
        } else {
            liveExercises[exerciseIndex].completedReps[setIndex] = reps
            if liveExercises[exerciseIndex].isCompleted[setIndex] {
                persistSet(exerciseIndex: exerciseIndex, setIndex: setIndex, reps: reps)
            }
        }
    }

    func adjustWeight(index: Int, delta: Double) {
        guard index < liveExercises.count else { return }
        let newVal = max(0, min(999, liveExercises[index].weight + delta))
        liveExercises[index].weight = newVal
    }

    func setWeight(index: Int, weight: Double) {
        guard index < liveExercises.count else { return }
        liveExercises[index].weight = max(0, min(999, weight))
    }

    func adjustRounds(delta: Int) {
        amrapRounds = max(0, amrapRounds + delta)
    }

    func setRounds(_ rounds: Int) {
        amrapRounds = max(0, rounds)
    }

    func skipRest() {
        restTimer.skip()
    }

    func advanceSession() {
        if currentSessionIndex < liveExercises.count - 1 {
            currentSessionIndex += 1
        }
    }

    // MARK: - Finish / Save

    func markForTimeComplete() {
        mainTimer.stop()
        handleMainTimerComplete()
    }

    func finishWorkout() {
        mainTimer.stop()
        restTimer.stop()
        completionMessage = CompletionMessages.random
        isWorkoutActive = false
    }

    func saveAndEnd() {
        persistAllData()
        finishWorkout()
        activeSession?.completedAt = Date()
        try? modelContext?.save()
    }

    func discardWorkout() {
        mainTimer.stop()
        restTimer.stop()
        if let session = activeSession {
            modelContext?.delete(session)
            try? modelContext?.save()
        }
        activeSession   = nil
        isWorkoutActive = false
        liveExercises   = []
    }

    func dismissWorkout() {
        activeSession   = nil
        isWorkoutActive = false
        liveExercises   = []
        amrapRounds     = 0
    }

    // MARK: - Template save

    func saveAsTemplate(name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            templateSaveError = "Template name cannot be empty."
            return false
        }

        guard let ctx = modelContext else { return false }

        // Check free tier limit
        let descriptor = FetchDescriptor<UserProfile>()
        let profile = (try? ctx.fetch(descriptor))?.first
        let templateDescriptor = FetchDescriptor<WorkoutTemplate>()
        let existingTemplates = (try? ctx.fetch(templateDescriptor)) ?? []

        if profile == nil || profile?.isPremium == false {
            if existingTemplates.count >= UserProfile.maxFreeTemplates {
                templateSaveError = "Free accounts limited to \(UserProfile.maxFreeTemplates) templates. Sign in for premium."
                return false
            }
        }

        let template = WorkoutTemplate(name: trimmed)
        ctx.insert(template)

        if setupType == .reps {
            for (i, ex) in setupExercises.enumerated() {
                let exerciseObj = findOrCreateExercise(name: ex.name, equipment: ex.equipment, in: ctx)
                let te = TemplateExercise(
                    exercise: exerciseObj,
                    timerType: setupType,
                    timerConfig: setupConfig,
                    targetSets: ex.sets,
                    targetReps: ex.reps,
                    sortOrder: i
                )
                te.template = template
                ctx.insert(te)
            }
        } else {
            for (i, ss) in setupSessions.enumerated() {
                let exerciseObj = findOrCreateExercise(name: ss.name, equipment: ss.equipment, in: ctx)
                let te = TemplateExercise(
                    exercise: exerciseObj,
                    timerType: setupType,
                    timerConfig: setupConfig,
                    targetSets: 1,
                    targetReps: 1,
                    sortOrder: i
                )
                te.template = template
                ctx.insert(te)
            }
        }

        try? ctx.save()
        templateSaveError = nil
        return true
    }

    func clearTemplateError() {
        templateSaveError = nil
    }

    // MARK: - Private helpers

    private func handleMainTimerComplete() {
        HapticManager.shared.timerComplete()
        completionMessage = CompletionMessages.random
        saveAndEnd()
    }

    private func handleRestTimerComplete() {
        HapticManager.shared.timerComplete()
    }

    private func findOrCreateExercise(name: String, equipment: Equipment?, in ctx: ModelContext) -> Exercise {
        let lower = name.lowercased()
        let descriptor = FetchDescriptor<Exercise>(predicate: #Predicate { $0.name.lowercased() == lower })
        if let existing = try? ctx.fetch(descriptor), let found = existing.first {
            return found
        }
        let ex = Exercise(name: name.isEmpty ? "Workout" : name, equipment: equipment, isCustom: true)
        ctx.insert(ex)
        return ex
    }

    private func persistSet(exerciseIndex: Int, setIndex: Int, reps: Int) {
        guard let ctx = modelContext, let session = activeSession else { return }
        let live = liveExercises[exerciseIndex]
        let exerciseObj = findOrCreateExercise(name: live.name, equipment: live.equipment, in: ctx)

        let sortedEntries = session.entries.sorted { $0.sortOrder < $1.sortOrder }
        let entry: WorkoutEntry
        if exerciseIndex < sortedEntries.count {
            entry = sortedEntries[exerciseIndex]
        } else {
            let newEntry = WorkoutEntry(exercise: exerciseObj, session: session,
                                       timerType: setupType, sortOrder: exerciseIndex)
            ctx.insert(newEntry)
            entry = newEntry
        }

        let set = SetRecord(
            setNumber: setIndex + 1,
            weight: live.weight,
            weightUnit: live.weightUnit,
            reps: reps,
            plannedWeight: live.weight,
            plannedReps: live.plannedReps
        )
        set.entry = entry
        ctx.insert(set)

        // Check PRs
        let newPRTypes = prService?.evaluate(set: set, exercise: exerciseObj) ?? []
        if !newPRTypes.isEmpty {
            HapticManager.shared.personalRecord()
            prBanners.append(PRBanner(types: newPRTypes))
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.prBanners.removeFirst()
            }
        }

        try? ctx.save()
    }

    private func persistAllData() {
        guard let ctx = modelContext, let session = activeSession else { return }
        if setupType == .amrap {
            // Store rounds count in notes if not already captured
            if session.notes == nil || session.notes!.isEmpty {
                session.notes = "Rounds: \(amrapRounds)"
            }
        }
        try? ctx.save()
    }
}
