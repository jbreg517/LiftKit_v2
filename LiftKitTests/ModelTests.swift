import XCTest
import SwiftData
@testable import LiftKit

@MainActor
final class ModelTests: XCTestCase {

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

    // MARK: - WorkoutSession

    func testSessionDurationCalculation() {
        let session = WorkoutSession(name: "Test")
        session.completedAt = Date(timeIntervalSinceNow: 1800)
        XCTAssertGreaterThan(session.duration, 1799)
    }

    func testSessionIsActive() {
        let session = WorkoutSession(name: "Active")
        XCTAssertTrue(session.isActive)
        session.completedAt = Date()
        XCTAssertFalse(session.isActive)
    }

    func testSessionTotalVolume() {
        let session = WorkoutSession(name: "Vol")
        let exercise = Exercise(name: "Bench")
        let entry = WorkoutEntry(exercise: exercise, session: session)
        let set1 = SetRecord(setNumber: 1, weight: 100, reps: 10)
        let set2 = SetRecord(setNumber: 2, weight: 100, reps: 8)
        set1.entry = entry
        set2.entry = entry
        modelContext.insert(session)
        modelContext.insert(exercise)
        modelContext.insert(entry)
        modelContext.insert(set1)
        modelContext.insert(set2)
        XCTAssertEqual(session.totalVolume, 1800)
    }

    func testSessionFormattedDuration() {
        let session = WorkoutSession(name: "Test")
        session.completedAt = Date(timeIntervalSinceNow: 2700) // 45 min
        XCTAssertFalse(session.formattedDuration.isEmpty)
    }

    // MARK: - WorkoutEntry

    func testEntrySortedSets() {
        let entry = WorkoutEntry()
        let set3 = SetRecord(setNumber: 3, reps: 10)
        let set1 = SetRecord(setNumber: 1, reps: 10)
        let set2 = SetRecord(setNumber: 2, reps: 10)
        set1.entry = entry
        set2.entry = entry
        set3.entry = entry
        modelContext.insert(entry)
        modelContext.insert(set1)
        modelContext.insert(set2)
        modelContext.insert(set3)
        XCTAssertEqual(entry.sortedSets.map(\.setNumber), [1, 2, 3])
    }

    func testEntryNextSetNumber() {
        let entry = WorkoutEntry()
        XCTAssertEqual(entry.nextSetNumber, 1)
        let set = SetRecord(setNumber: 3)
        set.entry = entry
        modelContext.insert(entry)
        modelContext.insert(set)
        XCTAssertEqual(entry.nextSetNumber, 4)
    }

    // MARK: - SetRecord

    func testSetRecordVolume() {
        let set = SetRecord(setNumber: 1, weight: 135, reps: 10)
        XCTAssertEqual(set.volume, 1350)
    }

    func testSetRecordWeightUnit() {
        let set = SetRecord(setNumber: 1, weightUnit: .kg)
        XCTAssertEqual(set.weightUnit, .kg)
        set.weightUnit = .lb
        XCTAssertEqual(set.weightUnitRaw, "lb")
    }

    // MARK: - WorkoutTemplate

    func testTemplateExerciseSortOrder() throws {
        let template = WorkoutTemplate(name: "Test")
        modelContext.insert(template)
        for i in [2, 0, 1] {
            let ex = Exercise(name: "Ex \(i)")
            let te = TemplateExercise(exercise: ex, sortOrder: i)
            te.template = template
            modelContext.insert(ex)
            modelContext.insert(te)
        }
        try modelContext.save()
        let sorted = template.exercises.sorted { $0.sortOrder < $1.sortOrder }
        XCTAssertEqual(sorted.map(\.sortOrder), [0, 1, 2])
    }

    // MARK: - PersonalRecord

    func testPersonalRecordType() {
        let pr = PersonalRecord(type: .maxVolume, value: 2700)
        XCTAssertEqual(pr.type, .maxVolume)
        XCTAssertEqual(pr.value, 2700)
    }

    // MARK: - TimerType

    func testTimerTypeRawValues() {
        XCTAssertEqual(TimerType.amrap.rawValue, "AMRAP")
        XCTAssertEqual(TimerType.emom.rawValue, "EMOM")
        XCTAssertEqual(TimerType.forTime.rawValue, "For Time")
        XCTAssertEqual(TimerType.intervals.rawValue, "Intervals")
        XCTAssertEqual(TimerType.reps.rawValue, "Reps")
        XCTAssertEqual(TimerType.manual.rawValue, "Manual")
    }

    func testTimerTypeIsCountdown() {
        XCTAssertTrue(TimerType.amrap.isCountdown)
        XCTAssertTrue(TimerType.emom.isCountdown)
        XCTAssertTrue(TimerType.intervals.isCountdown)
        XCTAssertFalse(TimerType.forTime.isCountdown)
        XCTAssertFalse(TimerType.manual.isCountdown)
        XCTAssertFalse(TimerType.reps.isCountdown)
    }

    // MARK: - Exercise

    func testExerciseEquipmentCases() {
        XCTAssertEqual(Equipment.allCases.count, 9)
    }

    func testExerciseCategoryCases() {
        XCTAssertEqual(ExerciseCategory.allCases.count, 7)
    }
}
