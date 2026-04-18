import XCTest
import SwiftData
@testable import LiftKit

@MainActor
final class WorkoutViewModelTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var vm: WorkoutViewModel!

    override func setUpWithError() throws {
        let schema = Schema([
            Exercise.self, WorkoutSession.self, WorkoutEntry.self, SetRecord.self,
            PersonalRecord.self, WorkoutTemplate.self, TemplateExercise.self,
            UserProfile.self, WorkoutSchedule.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [config])
        modelContext = modelContainer.mainContext
        vm = WorkoutViewModel()
        vm.configure(modelContext: modelContext)
    }

    override func tearDownWithError() throws {
        vm.discardWorkout()
        modelContainer = nil
        modelContext = nil
        vm = nil
    }

    // MARK: - resetSetup

    func testResetSetupClearsState() {
        vm.setupName = "Old Name"
        vm.setupNotes = "Old Notes"
        vm.resetSetup(for: .emom)
        XCTAssertEqual(vm.setupType, .emom)
        XCTAssertEqual(vm.setupName, "")
        XCTAssertEqual(vm.setupNotes, "")
        XCTAssertEqual(vm.setupConfig.type, .emom)
    }

    func testResetSetupForAllTypes() {
        for type in TimerType.allCases {
            vm.resetSetup(for: type)
            XCTAssertEqual(vm.setupType, type)
            XCTAssertEqual(vm.setupConfig.type, type)
        }
    }

    // MARK: - Default configs

    func testAMRAPDefaultConfig() {
        vm.resetSetup(for: .amrap)
        XCTAssertEqual(vm.setupConfig.durationMinutes, 10)
        XCTAssertEqual(vm.setupConfig.rounds, 1)
    }

    func testEMOMDefaultConfig() {
        vm.resetSetup(for: .emom)
        XCTAssertEqual(vm.setupConfig.rounds, 10)
        XCTAssertEqual(vm.setupConfig.workSeconds, 60)
    }

    func testForTimeDefaultConfig() {
        vm.resetSetup(for: .forTime)
        XCTAssertEqual(vm.setupConfig.durationMinutes, 20)
    }

    func testIntervalsDefaultConfig() {
        vm.resetSetup(for: .intervals)
        XCTAssertEqual(vm.setupConfig.rounds, 8)
        XCTAssertEqual(vm.setupConfig.workSeconds, 40)
        XCTAssertEqual(vm.setupConfig.restSeconds, 20)
    }

    func testRepsDefaultConfig() {
        vm.resetSetup(for: .reps)
        XCTAssertEqual(vm.setupConfig.restBetweenSets, 90)
    }

    // MARK: - startWorkout

    func testStartWorkoutCreatesSession() throws {
        vm.resetSetup(for: .amrap)
        vm.setupName = "Morning AMRAP"
        vm.startWorkout()
        XCTAssertNotNil(vm.activeSession)
        XCTAssertEqual(vm.activeSession?.name, "Morning AMRAP")
        XCTAssertTrue(vm.isWorkoutActive)
        vm.discardWorkout()
    }

    func testStartWorkoutDefaultsNameToType() throws {
        vm.resetSetup(for: .intervals)
        vm.setupName = ""
        vm.startWorkout()
        XCTAssertEqual(vm.activeSession?.name, "Intervals")
        vm.discardWorkout()
    }

    func testStartWorkoutSetsWorkoutType() throws {
        vm.resetSetup(for: .emom)
        vm.startWorkout()
        XCTAssertEqual(vm.activeSession?.workoutType, "EMOM")
        vm.discardWorkout()
    }

    func testStartRepsWorkoutCreatesLiveExercises() {
        vm.resetSetup(for: .reps)
        var ex = SetupExercise()
        ex.name = "Bench Press"
        ex.sets = 4
        ex.reps = 8
        vm.setupExercises = [ex]
        vm.startWorkout()
        XCTAssertEqual(vm.liveExercises.count, 1)
        XCTAssertEqual(vm.liveExercises[0].plannedSets, 4)
        XCTAssertEqual(vm.liveExercises[0].plannedReps, 8)
        vm.discardWorkout()
    }

    // MARK: - completeSet

    func testCompleteSetMarksSetDone() {
        vm.resetSetup(for: .reps)
        vm.setupExercises = [SetupExercise()]
        vm.startWorkout()
        XCTAssertFalse(vm.liveExercises[0].isCompleted[0])
        vm.completeSet(exerciseIndex: 0, setIndex: 0)
        XCTAssertTrue(vm.liveExercises[0].isCompleted[0])
        vm.discardWorkout()
    }

    func testCompleteSetStartsRestTimer() {
        vm.resetSetup(for: .reps)
        vm.setupConfig.restBetweenSets = 60
        vm.setupExercises = [SetupExercise()]
        vm.startWorkout()
        vm.completeSet(exerciseIndex: 0, setIndex: 0)
        if case .rest = vm.restTimer.phase { } else {
            XCTFail("Rest timer should be in .rest phase after completing a set")
        }
        vm.discardWorkout()
    }

    // MARK: - skipRest

    func testSkipRestEndsRestTimer() {
        vm.resetSetup(for: .reps)
        vm.setupExercises = [SetupExercise()]
        vm.startWorkout()
        vm.completeSet(exerciseIndex: 0, setIndex: 0)
        vm.skipRest()
        if case .rest = vm.restTimer.phase {
            XCTFail("Rest timer should not be in .rest after skip")
        }
        vm.discardWorkout()
    }

    // MARK: - adjustWeight

    func testAdjustWeightIncrements() {
        vm.resetSetup(for: .reps)
        var ex = SetupExercise()
        ex.weight = 100
        vm.setupExercises = [ex]
        vm.startWorkout()
        vm.adjustWeight(index: 0, delta: 5)
        XCTAssertEqual(vm.liveExercises[0].weight, 105)
        vm.discardWorkout()
    }

    func testAdjustWeightFloorAtZero() {
        vm.resetSetup(for: .reps)
        var ex = SetupExercise()
        ex.weight = 10
        vm.setupExercises = [ex]
        vm.startWorkout()
        vm.adjustWeight(index: 0, delta: -100)
        XCTAssertEqual(vm.liveExercises[0].weight, 0)
        vm.discardWorkout()
    }

    func testAdjustWeightCeilsAt999() {
        vm.resetSetup(for: .reps)
        var ex = SetupExercise()
        ex.weight = 995
        vm.setupExercises = [ex]
        vm.startWorkout()
        vm.adjustWeight(index: 0, delta: 100)
        XCTAssertEqual(vm.liveExercises[0].weight, 999)
        vm.discardWorkout()
    }

    // MARK: - adjustRounds (AMRAP)

    func testAdjustRoundsIncrement() {
        vm.resetSetup(for: .amrap)
        vm.startWorkout()
        vm.adjustRounds(delta: 3)
        XCTAssertEqual(vm.amrapRounds, 3)
        vm.discardWorkout()
    }

    func testAdjustRoundsFloorAtZero() {
        vm.resetSetup(for: .amrap)
        vm.startWorkout()
        vm.adjustRounds(delta: -10)
        XCTAssertEqual(vm.amrapRounds, 0)
        vm.discardWorkout()
    }

    // MARK: - finishWorkout / discardWorkout

    func testFinishWorkoutSetsCompletionMessage() {
        vm.resetSetup(for: .amrap)
        vm.startWorkout()
        vm.finishWorkout()
        XCTAssertFalse(vm.completionMessage.isEmpty)
        XCTAssertFalse(vm.isWorkoutActive)
        vm.discardWorkout()
    }

    func testDiscardWorkoutDeletesSession() throws {
        vm.resetSetup(for: .amrap)
        vm.startWorkout()
        let id = vm.activeSession?.id
        vm.discardWorkout()
        XCTAssertNil(vm.activeSession)
        let sessions = try modelContext.fetch(FetchDescriptor<WorkoutSession>())
        XCTAssertFalse(sessions.contains { $0.id == id })
    }

    // MARK: - saveAsTemplate

    func testSaveAsTemplateSucceeds() throws {
        vm.resetSetup(for: .reps)
        vm.setupExercises = [SetupExercise()]
        let result = vm.saveAsTemplate(name: "Push Day")
        XCTAssertTrue(result)
        let templates = try modelContext.fetch(FetchDescriptor<WorkoutTemplate>())
        XCTAssertTrue(templates.contains { $0.name == "Push Day" })
    }

    func testSaveAsTemplateFailsEmptyName() {
        vm.resetSetup(for: .reps)
        vm.setupExercises = [SetupExercise()]
        XCTAssertFalse(vm.saveAsTemplate(name: ""))
        XCTAssertNotNil(vm.templateSaveError)
    }

    // MARK: - loadTemplate (startFromTemplate)

    func testStartFromTemplateLoadsConfig() throws {
        let template = WorkoutTemplate(name: "My Template")
        let exercise = Exercise(name: "Squat", equipment: .barbell)
        modelContext.insert(exercise)
        let te = TemplateExercise(exercise: exercise, timerType: .reps, targetSets: 5, targetReps: 5)
        te.template = template
        modelContext.insert(template)
        modelContext.insert(te)
        try modelContext.save()

        vm.startFromTemplate(template)
        XCTAssertEqual(vm.activeSession?.name, "My Template")
        vm.discardWorkout()
    }

    // MARK: - repeatWorkout

    func testRepeatWorkoutCreatesNewActiveSession() throws {
        vm.resetSetup(for: .reps)
        vm.startWorkout()
        let original = vm.activeSession!
        original.completedAt = Date()
        try modelContext.save()
        vm.discardWorkout()

        vm.repeatWorkout(original)
        XCTAssertNotNil(vm.activeSession)
        XCTAssertNotEqual(vm.activeSession?.id, original.id)
        vm.discardWorkout()
    }

    // MARK: - forTime markComplete

    func testForTimeMarkCompleteSavesWorkout() {
        vm.resetSetup(for: .forTime)
        vm.startWorkout()
        vm.markForTimeComplete()
        XCTAssertFalse(vm.isWorkoutActive)
        XCTAssertFalse(vm.completionMessage.isEmpty)
    }
}
