import XCTest
import SwiftData
@testable import LiftKit

@MainActor
final class FeatureGapTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    override func setUpWithError() throws {
        let schema = Schema([
            Exercise.self, WorkoutSession.self, WorkoutEntry.self, SetRecord.self,
            PersonalRecord.self, WorkoutTemplate.self, TemplateExercise.self,
            UserProfile.self, WorkoutSchedule.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [config])
        modelContext = modelContainer.mainContext
    }

    override func tearDownWithError() throws {
        modelContainer = nil
        modelContext = nil
    }

    // MARK: - SetRecord Tests

    func testSetRecordTracksPlannedReps() throws {
        let set = SetRecord(setNumber: 1, reps: 8, plannedReps: 10)
        XCTAssertEqual(set.reps, 8)
        XCTAssertEqual(set.plannedReps, 10)
    }

    func testSetRecordTracksPlannedWeight() throws {
        let set = SetRecord(setNumber: 1, weight: 185, plannedWeight: 200)
        XCTAssertEqual(set.weight, 185)
        XCTAssertEqual(set.plannedWeight, 200)
    }

    func testSetRecordNilPlannedValues() throws {
        let set = SetRecord(setNumber: 1, weight: 100, reps: 5)
        XCTAssertNil(set.plannedWeight)
        XCTAssertNil(set.plannedReps)
    }

    // MARK: - Notes Tests

    func testWorkoutSessionStoresNotes() throws {
        let session = WorkoutSession(name: "Morning", notes: "Felt great")
        modelContext.insert(session)
        try modelContext.save()
        let fetched = try modelContext.fetch(FetchDescriptor<WorkoutSession>()).first
        XCTAssertEqual(fetched?.notes, "Felt great")
    }

    func testWorkoutTypeSavedToSession() throws {
        let session = WorkoutSession(name: "Test", workoutType: TimerType.amrap.rawValue)
        modelContext.insert(session)
        try modelContext.save()
        let fetched = try modelContext.fetch(FetchDescriptor<WorkoutSession>()).first
        XCTAssertEqual(fetched?.workoutType, "AMRAP")
        XCTAssertEqual(fetched?.timerType, .amrap)
    }

    // MARK: - WeightCache Tests

    func testWeightCacheLookup() throws {
        let exercise = Exercise(name: "Bench Press", equipment: .barbell)
        modelContext.insert(exercise)
        let session = WorkoutSession(name: "Test")
        modelContext.insert(session)
        let entry = WorkoutEntry(exercise: exercise, session: session, timerType: .reps)
        modelContext.insert(entry)
        let set = SetRecord(setNumber: 1, weight: 135, reps: 10)
        set.entry = entry
        modelContext.insert(set)
        try modelContext.save()

        let cache = WeightCache(modelContext: modelContext)
        let result = cache.lookup(exerciseName: "Bench Press")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.weight, 135)
    }

    func testWeightCacheBatchLookup() throws {
        for (name, weight) in [("Squat", 225.0), ("Deadlift", 315.0)] {
            let ex = Exercise(name: name)
            modelContext.insert(ex)
            let session = WorkoutSession(name: "Test")
            modelContext.insert(session)
            let entry = WorkoutEntry(exercise: ex, session: session)
            modelContext.insert(entry)
            let set = SetRecord(setNumber: 1, weight: weight, reps: 5)
            set.entry = entry
            modelContext.insert(set)
        }
        try modelContext.save()

        let cache = WeightCache(modelContext: modelContext)
        let results = cache.batchLookup(names: ["Squat", "Deadlift"])
        XCTAssertEqual(results["Squat"]?.weight, 225)
        XCTAssertEqual(results["Deadlift"]?.weight, 315)
    }

    func testWeightCacheMiss() throws {
        let cache = WeightCache(modelContext: modelContext)
        let result = cache.lookup(exerciseName: "Unknown Exercise")
        XCTAssertNil(result)
    }

    // MARK: - Template Limit Tests

    func testMaxTemplatesForNonPremium() throws {
        let vm = WorkoutViewModel()
        vm.configure(modelContext: modelContext)

        for i in 1...5 {
            vm.resetSetup(for: .reps)
            vm.setupExercises = [SetupExercise()]
            let saved = vm.saveAsTemplate(name: "Template \(i)")
            XCTAssertTrue(saved, "Should save template \(i)")
        }

        vm.resetSetup(for: .reps)
        vm.setupExercises = [SetupExercise()]
        let saved6 = vm.saveAsTemplate(name: "Template 6")
        XCTAssertFalse(saved6, "Free user should not save 6th template")
    }

    func testPremiumCanSaveUnlimitedTemplates() throws {
        let profile = UserProfile(isPremium: true)
        modelContext.insert(profile)
        try modelContext.save()

        let vm = WorkoutViewModel()
        vm.configure(modelContext: modelContext)
        for i in 1...6 {
            vm.resetSetup(for: .reps)
            vm.setupExercises = [SetupExercise()]
            let saved = vm.saveAsTemplate(name: "Template \(i)")
            XCTAssertTrue(saved, "Premium user should save template \(i)")
        }
    }

    // MARK: - Completion Messages

    func testCompletionMessagesExist() {
        XCTAssertGreaterThan(CompletionMessages.all.count, 10)
        XCTAssertEqual(CompletionMessages.all.count, 55)
    }

    func testCompletionMessageRandom() {
        let msg = CompletionMessages.random
        XCTAssertFalse(msg.isEmpty)
        XCTAssertTrue(CompletionMessages.all.contains(msg))
    }

    // MARK: - Repeat Workout

    func testRepeatWorkoutCreatesNewSession() throws {
        let vm = WorkoutViewModel()
        vm.configure(modelContext: modelContext)
        vm.resetSetup(for: .reps)
        vm.startWorkout()

        let original = vm.activeSession!
        let originalId = original.id
        original.completedAt = Date()
        try modelContext.save()

        vm.repeatWorkout(original)
        let newSession = vm.activeSession!
        XCTAssertNotEqual(newSession.id, originalId)
        vm.discardWorkout()
    }

    // MARK: - Save Template Validation

    func testSaveAsTemplateRequiresName() throws {
        let vm = WorkoutViewModel()
        vm.configure(modelContext: modelContext)
        vm.resetSetup(for: .reps)
        vm.setupExercises = [SetupExercise()]
        let result = vm.saveAsTemplate(name: "")
        XCTAssertFalse(result)
        XCTAssertNotNil(vm.templateSaveError)
    }

    func testSaveAsTemplateWhitespaceOnlyName() throws {
        let vm = WorkoutViewModel()
        vm.configure(modelContext: modelContext)
        vm.resetSetup(for: .reps)
        vm.setupExercises = [SetupExercise()]
        let result = vm.saveAsTemplate(name: "   ")
        XCTAssertFalse(result)
    }

    func testSaveAsTemplateValidName() throws {
        let vm = WorkoutViewModel()
        vm.configure(modelContext: modelContext)
        vm.resetSetup(for: .reps)
        vm.setupExercises = [SetupExercise()]
        let result = vm.saveAsTemplate(name: "My Template")
        XCTAssertTrue(result)
        let templates = try modelContext.fetch(FetchDescriptor<WorkoutTemplate>())
        XCTAssertTrue(templates.contains { $0.name == "My Template" })
    }

    // MARK: - Reps Adjustments

    func testRepsCanBeAdjustedDuringWorkout() throws {
        let vm = WorkoutViewModel()
        vm.configure(modelContext: modelContext)
        vm.resetSetup(for: .reps)
        vm.setupExercises = [SetupExercise()]
        vm.startWorkout()

        vm.completeSet(exerciseIndex: 0, setIndex: 0)
        vm.setActualReps(exerciseIndex: 0, setIndex: 0, reps: 12)
        XCTAssertEqual(vm.liveExercises[0].completedReps[0], 12)

        vm.setActualReps(exerciseIndex: 0, setIndex: 0, reps: 0)
        XCTAssertFalse(vm.liveExercises[0].isCompleted[0])

        vm.discardWorkout()
    }

    func testWeightCanBeAdjustedDuringWorkout() throws {
        let vm = WorkoutViewModel()
        vm.configure(modelContext: modelContext)
        vm.resetSetup(for: .reps)
        var ex = SetupExercise()
        ex.weight = 100
        vm.setupExercises = [ex]
        vm.startWorkout()

        vm.adjustWeight(index: 0, delta: 5)
        XCTAssertEqual(vm.liveExercises[0].weight, 105)

        vm.adjustWeight(index: 0, delta: -200)
        XCTAssertEqual(vm.liveExercises[0].weight, 0, "Weight should not go below 0")

        vm.discardWorkout()
    }

    // MARK: - WorkoutSchedule

    func testScheduledWorkoutCreation() throws {
        let schedule = WorkoutSchedule(date: Date(), customName: "Leg Day")
        modelContext.insert(schedule)
        try modelContext.save()

        let fetched = try modelContext.fetch(FetchDescriptor<WorkoutSchedule>()).first
        XCTAssertNotNil(fetched)
        XCTAssertFalse(fetched!.isCompleted)
        XCTAssertEqual(fetched!.customName, "Leg Day")
    }

    func testScheduledWorkoutWithTemplate() throws {
        let template = WorkoutTemplate(name: "Push Day")
        modelContext.insert(template)
        let schedule = WorkoutSchedule(date: Date(), template: template)
        modelContext.insert(schedule)
        try modelContext.save()

        XCTAssertEqual(schedule.displayName, "Push Day")
    }

    // MARK: - UserProfile

    func testUserProfileCreation() throws {
        let profile = UserProfile(displayName: "John", email: "john@example.com",
                                   authProvider: "apple", isPremium: true)
        modelContext.insert(profile)
        try modelContext.save()

        let fetched = try modelContext.fetch(FetchDescriptor<UserProfile>()).first
        XCTAssertEqual(fetched?.displayName, "John")
        XCTAssertEqual(fetched?.email, "john@example.com")
        XCTAssertEqual(fetched?.authProvider, "apple")
        XCTAssertTrue(fetched?.isPremium == true)
    }

    func testUserProfileDefaultsNotPremium() throws {
        let profile = UserProfile()
        modelContext.insert(profile)
        try modelContext.save()

        let fetched = try modelContext.fetch(FetchDescriptor<UserProfile>()).first
        XCTAssertFalse(fetched?.isPremium == true)
        XCTAssertNil(fetched?.authProvider)
    }
}
