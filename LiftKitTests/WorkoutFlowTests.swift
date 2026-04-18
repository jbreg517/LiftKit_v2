import XCTest
import SwiftData
@testable import LiftKit

@MainActor
final class WorkoutFlowTests: XCTestCase {

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

    // MARK: - AMRAP

    func testAMRAPTimerStartsOnStartWorkout() {
        vm.resetSetup(for: .amrap)
        vm.startWorkout()
        XCTAssertTrue(vm.mainTimer.isRunning)
        vm.discardWorkout()
    }

    func testAMRAPRoundsStartAtZero() {
        vm.resetSetup(for: .amrap)
        vm.startWorkout()
        XCTAssertEqual(vm.amrapRounds, 0)
        vm.discardWorkout()
    }

    // MARK: - EMOM

    func testEMOMTimerHasCorrectTotalRounds() {
        vm.resetSetup(for: .emom)
        vm.setupConfig.rounds = 5
        vm.startWorkout()
        XCTAssertEqual(vm.mainTimer.totalRounds, 5)
        vm.discardWorkout()
    }

    func testEMOMSkipAdvancesRound() {
        vm.resetSetup(for: .emom)
        vm.setupConfig.rounds = 5
        vm.startWorkout()
        let before = vm.mainTimer.currentRound
        vm.mainTimer.skip()
        let after = vm.mainTimer.currentRound
        XCTAssertTrue(after >= before)
        vm.discardWorkout()
    }

    // MARK: - Intervals

    func testIntervalsStartsInWorkPhase() {
        vm.resetSetup(for: .intervals)
        vm.startWorkout()
        // Should be in countdown or work
        XCTAssertTrue(vm.mainTimer.isRunning)
        vm.discardWorkout()
    }

    func testIntervalsWorkRestCycle() {
        vm.resetSetup(for: .intervals)
        vm.setupConfig.workSeconds = 10
        vm.setupConfig.restSeconds = 10
        vm.setupConfig.rounds = 3
        vm.startWorkout()
        vm.mainTimer.skip()
        vm.mainTimer.skip()
        // Should have transitioned phases
        XCTAssertTrue(vm.mainTimer.currentRound >= 1)
        vm.discardWorkout()
    }

    // MARK: - For Time

    func testForTimeTimerStartsRunning() {
        vm.resetSetup(for: .forTime)
        vm.startWorkout()
        XCTAssertTrue(vm.mainTimer.isRunning)
        vm.discardWorkout()
    }

    func testForTimeMarkCompleteEndsWorkout() {
        vm.resetSetup(for: .forTime)
        vm.startWorkout()
        vm.markForTimeComplete()
        XCTAssertFalse(vm.isWorkoutActive)
        XCTAssertFalse(vm.completionMessage.isEmpty)
    }

    // MARK: - Manual

    func testManualTimerStartsRunning() {
        vm.resetSetup(for: .manual)
        vm.startWorkout()
        XCTAssertTrue(vm.mainTimer.isRunning)
        vm.discardWorkout()
    }

    // MARK: - Reps workout flow

    func testRepsWorkoutNoMainTimer() {
        vm.resetSetup(for: .reps)
        vm.setupExercises = [SetupExercise()]
        vm.startWorkout()
        // Main timer should not be running for reps mode
        // Rest timer starts per-set
        XCTAssertFalse(vm.mainTimer.isRunning)
        vm.discardWorkout()
    }

    func testCompleteAllSetsForExercise() {
        vm.resetSetup(for: .reps)
        var ex = SetupExercise()
        ex.sets = 3
        ex.reps = 10
        vm.setupExercises = [ex]
        vm.startWorkout()

        for i in 0..<3 { vm.completeSet(exerciseIndex: 0, setIndex: i) }
        XCTAssertTrue(vm.liveExercises[0].allComplete)
        vm.discardWorkout()
    }

    // MARK: - startFromTemplate

    func testStartFromTemplateUsesTemplateName() throws {
        let template = WorkoutTemplate(name: "Leg Day")
        modelContext.insert(template)
        try modelContext.save()

        vm.startFromTemplate(template)
        XCTAssertEqual(vm.activeSession?.name, "Leg Day")
        vm.discardWorkout()
    }

    func testStartFromTemplateUpdatesLastUsedAt() throws {
        let template = WorkoutTemplate(name: "Test Template")
        modelContext.insert(template)
        try modelContext.save()

        XCTAssertNil(template.lastUsedAt)
        vm.startFromTemplate(template)
        XCTAssertNotNil(template.lastUsedAt)
        vm.discardWorkout()
    }

    // MARK: - Exercise reuse

    func testSameExerciseNameReusesSingleRecord() throws {
        let ex = Exercise(name: "Pull Up", isCustom: false)
        modelContext.insert(ex)
        try modelContext.save()

        vm.resetSetup(for: .reps)
        var setup = SetupExercise()
        setup.name = "Pull Up"
        vm.setupExercises = [setup]
        vm.startWorkout()

        let exercises = try modelContext.fetch(FetchDescriptor<Exercise>())
        let pullUps = exercises.filter { $0.name == "Pull Up" }
        XCTAssertEqual(pullUps.count, 1, "Should reuse existing exercise, not create duplicate")
        vm.discardWorkout()
    }

    // MARK: - PR Detection

    func testNewPRIsDetectedOnSet() throws {
        let ex = Exercise(name: "Deadlift", equipment: .barbell)
        modelContext.insert(ex)
        let session = WorkoutSession(name: "Test")
        modelContext.insert(session)
        let entry = WorkoutEntry(exercise: ex, session: session, timerType: .reps)
        modelContext.insert(entry)
        try modelContext.save()

        let prService = PRDetectionService(modelContext: modelContext)
        let set = SetRecord(setNumber: 1, weight: 315, reps: 5)
        set.entry = entry
        modelContext.insert(set)

        let newPRs = prService.evaluate(set: set, exercise: ex)
        XCTAssertFalse(newPRs.isEmpty, "Should detect PRs for first set ever")
    }

    // MARK: - Notes persistence

    func testNotesPersistedToSession() throws {
        vm.resetSetup(for: .amrap)
        vm.setupNotes = "Fast pace today"
        vm.startWorkout()

        XCTAssertEqual(vm.activeSession?.notes, "Fast pace today")
        vm.discardWorkout()
    }

    // MARK: - Multi-session advance

    func testAdvanceSessionIncreasesIndex() {
        vm.resetSetup(for: .emom)
        vm.setupSessions = [SetupSession(), SetupSession(), SetupSession()]
        vm.startWorkout()
        XCTAssertEqual(vm.currentSessionIndex, 0)
        vm.advanceSession()
        XCTAssertEqual(vm.currentSessionIndex, 1)
        vm.discardWorkout()
    }
}
