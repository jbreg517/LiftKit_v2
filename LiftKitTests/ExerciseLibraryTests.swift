import XCTest
import SwiftData
@testable import LiftKit

@MainActor
final class ExerciseLibraryTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    override func setUpWithError() throws {
        let schema = Schema([Exercise.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [config])
        modelContext = modelContainer.mainContext
    }

    override func tearDownWithError() throws {
        modelContainer = nil
        modelContext = nil
    }

    func testSeedPopulatesExercises() throws {
        ExerciseLibrary.seed(in: modelContext)
        let exercises = try modelContext.fetch(FetchDescriptor<Exercise>())
        XCTAssertGreaterThan(exercises.count, 30, "Library should seed more than 30 exercises")
    }

    func testSeedIsIdempotent() throws {
        ExerciseLibrary.seed(in: modelContext)
        ExerciseLibrary.seed(in: modelContext)
        let exercises = try modelContext.fetch(FetchDescriptor<Exercise>())
        let names = exercises.map(\.name)
        let uniqueNames = Set(names)
        XCTAssertEqual(names.count, uniqueNames.count, "Seeding twice should not create duplicates")
    }

    func testSeedIncludesAllCategories() throws {
        ExerciseLibrary.seed(in: modelContext)
        let exercises = try modelContext.fetch(FetchDescriptor<Exercise>())
        let categories = Set(exercises.map(\.category))
        for cat in [ExerciseCategory.push, .pull, .legs, .core, .cardio] {
            XCTAssertTrue(categories.contains(cat), "Library should include \(cat.rawValue) exercises")
        }
    }

    func testSeedExercisesNotCustom() throws {
        ExerciseLibrary.seed(in: modelContext)
        let exercises = try modelContext.fetch(FetchDescriptor<Exercise>())
        XCTAssertTrue(exercises.allSatisfy { !$0.isCustom }, "Seeded exercises should not be marked as custom")
    }

    func testCommonExercisesPresent() throws {
        ExerciseLibrary.seed(in: modelContext)
        let exercises = try modelContext.fetch(FetchDescriptor<Exercise>())
        let names = Set(exercises.map(\.name))
        for name in ["Bench Press", "Squat", "Deadlift", "Pull Up", "Overhead Press"] {
            XCTAssertTrue(names.contains(name), "Library should include '\(name)'")
        }
    }
}
