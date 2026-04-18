import XCTest

final class LiftKitUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    // MARK: - Basic navigation

    func testAppLaunches() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5), "Tab bar should exist")
        XCTAssertTrue(app.tabBars.buttons["Workout"].exists)
        XCTAssertTrue(app.tabBars.buttons["History"].exists)
        XCTAssertTrue(app.tabBars.buttons["Progress"].exists)
        XCTAssertTrue(app.tabBars.buttons["Settings"].exists)
    }

    func testNavigateToSettings() throws {
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3))
    }

    func testNavigateToHistory() throws {
        app.tabBars.buttons["History"].tap()
        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 3))
    }

    func testNavigateToProgress() throws {
        app.tabBars.buttons["Progress"].tap()
        XCTAssertTrue(app.navigationBars["Progress"].waitForExistence(timeout: 3))
    }

    // MARK: - Workout Type Picker

    func testStartWorkoutOpensTypePicker() throws {
        let startButton = app.buttons["Start Workout Timer"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 3))
        startButton.tap()
        XCTAssertTrue(app.staticTexts["Choose Workout Type"].waitForExistence(timeout: 3))
    }

    func testTypePickerShowsAllTypes() throws {
        app.buttons["Start Workout Timer"].tap()
        _ = app.staticTexts["Choose Workout Type"].waitForExistence(timeout: 3)
        for type in ["AMRAP", "EMOM", "For Time", "Intervals", "Reps", "Manual"] {
            XCTAssertTrue(app.staticTexts[type].exists, "\(type) card should be visible")
        }
    }

    func testTypePickerCancel() throws {
        app.buttons["Start Workout Timer"].tap()
        _ = app.staticTexts["Choose Workout Type"].waitForExistence(timeout: 3)
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.buttons["Start Workout Timer"].waitForExistence(timeout: 3))
    }

    // MARK: - Setup screens

    func testAMRAPSetupFlow() throws {
        app.buttons["Start Workout Timer"].tap()
        _ = app.staticTexts["Choose Workout Type"].waitForExistence(timeout: 3)
        app.staticTexts["AMRAP"].tap()
        XCTAssertTrue(app.staticTexts["TIME LIMIT"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Start AMRAP"].exists)
    }

    func testAMRAPSetupBackButton() throws {
        app.buttons["Start Workout Timer"].tap()
        _ = app.staticTexts["Choose Workout Type"].waitForExistence(timeout: 3)
        app.staticTexts["AMRAP"].tap()
        _ = app.staticTexts["TIME LIMIT"].waitForExistence(timeout: 3)
        app.buttons["Back"].tap()
        XCTAssertTrue(app.buttons["Start Workout Timer"].waitForExistence(timeout: 3))
    }

    func testEMOMSetupFlow() throws {
        app.buttons["Start Workout Timer"].tap()
        _ = app.staticTexts["Choose Workout Type"].waitForExistence(timeout: 3)
        app.staticTexts["EMOM"].tap()
        XCTAssertTrue(app.staticTexts["TOTAL MINUTES"].waitForExistence(timeout: 3))
    }

    func testForTimeSetupFlow() throws {
        app.buttons["Start Workout Timer"].tap()
        _ = app.staticTexts["Choose Workout Type"].waitForExistence(timeout: 3)
        app.staticTexts["For Time"].tap()
        XCTAssertTrue(app.staticTexts["TIME CAP"].waitForExistence(timeout: 3))
    }

    func testIntervalsSetupFlow() throws {
        app.buttons["Start Workout Timer"].tap()
        _ = app.staticTexts["Choose Workout Type"].waitForExistence(timeout: 3)
        app.staticTexts["Intervals"].tap()
        XCTAssertTrue(app.staticTexts["WORK"].waitForExistence(timeout: 3) ||
                      app.staticTexts["WORK / REST / ROUNDS"].waitForExistence(timeout: 3))
    }

    func testRepsSetupFlow() throws {
        app.buttons["Start Workout Timer"].tap()
        _ = app.staticTexts["Choose Workout Type"].waitForExistence(timeout: 3)
        app.staticTexts["Reps"].tap()
        XCTAssertTrue(app.staticTexts["REST BETWEEN SETS"].waitForExistence(timeout: 3))
    }

    func testManualSetupFlow() throws {
        app.buttons["Start Workout Timer"].tap()
        _ = app.staticTexts["Choose Workout Type"].waitForExistence(timeout: 3)
        app.staticTexts["Manual"].tap()
        XCTAssertTrue(app.buttons["Start Manual"].waitForExistence(timeout: 3))
    }

    // MARK: - Active workout

    func testStartAMRAPWorkout() throws {
        navigateToAMRAPActive()
        XCTAssertTrue(app.buttons["End"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'ROUNDS COMPLETED'")).firstMatch.waitForExistence(timeout: 5))
        app.buttons["End"].tap()
        app.buttons["Discard"].tap()
    }

    func testEndWorkoutConfirmation() throws {
        navigateToAMRAPActive()
        _ = app.buttons["End"].waitForExistence(timeout: 3)
        app.buttons["End"].tap()
        XCTAssertTrue(app.buttons["Save & End"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Discard"].exists)
        XCTAssertTrue(app.buttons["Cancel"].exists)
        app.buttons["Discard"].tap()
    }

    // MARK: - Create workout

    func testAddNewWorkoutPlanButton() throws {
        let addButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'Add New Workout Plan'")).firstMatch
        XCTAssertTrue(addButton.waitForExistence(timeout: 3))
        addButton.tap()
        XCTAssertTrue(app.navigationBars["New Workout"].waitForExistence(timeout: 3))
    }

    func testCreateWorkoutCancel() throws {
        let addButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'Add New Workout Plan'")).firstMatch
        XCTAssertTrue(addButton.waitForExistence(timeout: 3))
        addButton.tap()
        _ = app.navigationBars["New Workout"].waitForExistence(timeout: 3)
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.buttons["Start Workout Timer"].waitForExistence(timeout: 3))
    }

    // MARK: - Helpers

    private func navigateToAMRAPActive() {
        app.buttons["Start Workout Timer"].tap()
        _ = app.staticTexts["Choose Workout Type"].waitForExistence(timeout: 3)
        app.staticTexts["AMRAP"].tap()
        _ = app.staticTexts["TIME LIMIT"].waitForExistence(timeout: 3)
        app.buttons["Start AMRAP"].tap()
    }
}
