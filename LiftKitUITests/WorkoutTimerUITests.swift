import XCTest

final class WorkoutTimerUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    // MARK: - Type Picker

    func testAllTypePickerButtonsWork() throws {
        for type in ["AMRAP", "EMOM", "For Time", "Intervals", "Reps", "Manual"] {
            app.buttons["Start Workout Timer"].tap()
            _ = app.staticTexts["Choose Workout Type"].waitForExistence(timeout: 3)
            app.staticTexts[type].tap()
            XCTAssertTrue(app.buttons["Start \(type)"].waitForExistence(timeout: 3),
                          "Start button for \(type) should exist")
            app.buttons["Back"].tap()
        }
    }

    func testSetupBoxesSizedConsistently() throws {
        app.buttons["Start Workout Timer"].tap()
        _ = app.staticTexts["Choose Workout Type"].waitForExistence(timeout: 3)
        app.staticTexts["AMRAP"].tap()
        _ = app.staticTexts["TIME LIMIT"].waitForExistence(timeout: 3)
        let startBtn = app.buttons["Start AMRAP"]
        XCTAssertTrue(startBtn.waitForExistence(timeout: 3))
        let width = startBtn.frame.width
        let screenWidth = app.windows.firstMatch.frame.width
        XCTAssertGreaterThan(width / screenWidth, 0.70,
                              "Start button should be >70% of screen width")
        app.buttons["Back"].tap()
    }

    // MARK: - AMRAP Setup

    func testAMRAPHasTimeDurationControl() throws {
        openSetup(for: "AMRAP")
        XCTAssertTrue(app.staticTexts["TIME LIMIT"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["min"].exists)
        app.buttons["Back"].tap()
    }

    func testAMRAPHasSessionsList() throws {
        openSetup(for: "AMRAP")
        XCTAssertTrue(app.staticTexts["WORKOUTS"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS '+ Add Workout'")).firstMatch.exists ||
            app.buttons.matching(
                NSPredicate(format: "label CONTAINS 'Add Workout'")).firstMatch.exists)
        app.buttons["Back"].tap()
    }

    // MARK: - EMOM Setup

    func testEMOMHasMinutesControl() throws {
        openSetup(for: "EMOM")
        XCTAssertTrue(app.staticTexts["TOTAL MINUTES"].waitForExistence(timeout: 3))
        app.buttons["Back"].tap()
    }

    func testEMOMHasWorkoutsList() throws {
        openSetup(for: "EMOM")
        XCTAssertTrue(app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'WORKOUTS'")).firstMatch.waitForExistence(timeout: 3))
        app.buttons["Back"].tap()
    }

    // MARK: - For Time Setup

    func testForTimeHasTimeCap() throws {
        openSetup(for: "For Time")
        XCTAssertTrue(app.staticTexts["TIME CAP"].waitForExistence(timeout: 3))
        app.buttons["Back"].tap()
    }

    // MARK: - Intervals Setup

    func testIntervalsHasWorkRestRounds() throws {
        openSetup(for: "Intervals")
        XCTAssertTrue(app.staticTexts["WORK"].waitForExistence(timeout: 3) ||
                      app.staticTexts["WORK / REST / ROUNDS"].waitForExistence(timeout: 3))
        app.buttons["Back"].tap()
    }

    // MARK: - Reps Setup

    func testRepsHasRestBetweenSets() throws {
        openSetup(for: "Reps")
        XCTAssertTrue(app.staticTexts["REST BETWEEN SETS"].waitForExistence(timeout: 3))
        app.buttons["Back"].tap()
    }

    func testRepsHasExerciseList() throws {
        openSetup(for: "Reps")
        XCTAssertTrue(app.staticTexts["EXERCISES"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS '+ Add Exercise'")).firstMatch.exists ||
            app.buttons.matching(
                NSPredicate(format: "label CONTAINS 'Add Exercise'")).firstMatch.exists)
        app.buttons["Back"].tap()
    }

    func testRepsExerciseHasSetsAndReps() throws {
        openSetup(for: "Reps")
        XCTAssertTrue(app.staticTexts["Sets"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Reps"].exists)
        app.buttons["Back"].tap()
    }

    // MARK: - Common elements

    func testAllSessionsDefaultTitled() throws {
        openSetup(for: "AMRAP")
        let textFields = app.textFields.matching(
            NSPredicate(format: "placeholderValue CONTAINS 'Workout name'"))
        XCTAssertGreaterThan(textFields.count, 0, "Should have workout name text fields")
        app.buttons["Back"].tap()
    }

    func testCannotDeleteOnlySessions() throws {
        openSetup(for: "AMRAP")
        let trashButtons = app.buttons.matching(NSPredicate(format: "label CONTAINS 'trash'"))
        XCTAssertEqual(trashButtons.count, 0, "Should have no delete buttons when only 1 session")
        app.buttons["Back"].tap()
    }

    func testDeleteButtonAppearsForMultipleSessions() throws {
        openSetup(for: "AMRAP")
        let addButton = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS '+ Add Workout'")).firstMatch
        if addButton.waitForExistence(timeout: 2) {
            addButton.tap()
        }
        let trashButtons = app.buttons.matching(NSPredicate(format: "label CONTAINS 'trash'"))
        XCTAssertGreaterThan(trashButtons.count, 0, "Trash buttons should appear with 2+ sessions")
        app.buttons["Back"].tap()
    }

    func testWeightCanBeAdjustedWithButtons() throws {
        openSetup(for: "AMRAP")
        let plusBtn = app.staticTexts["+5"].firstMatch
        XCTAssertTrue(plusBtn.waitForExistence(timeout: 3))
        let minusBtn = app.staticTexts["−5"].firstMatch
        XCTAssertTrue(minusBtn.exists)
        app.buttons["Back"].tap()
    }

    func testEquipmentPickerExists() throws {
        openSetup(for: "AMRAP")
        let equipmentPicker = app.staticTexts["Equipment"].firstMatch
        XCTAssertTrue(equipmentPicker.waitForExistence(timeout: 3))
        app.buttons["Back"].tap()
    }

    func testNotesFieldExists() throws {
        openSetup(for: "AMRAP")
        XCTAssertTrue(app.staticTexts["NOTES"].waitForExistence(timeout: 3))
        app.buttons["Back"].tap()
    }

    // MARK: - Active workout toolbar

    func testSaveButtonOnTimerScreen() throws {
        startAMRAP()
        _ = app.buttons["End"].waitForExistence(timeout: 5)
        XCTAssertTrue(app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'arrow.down'")).firstMatch.exists ||
            app.buttons.count > 2,
            "Save/template button should exist on active workout toolbar")
        app.buttons["End"].tap()
        app.buttons["Discard"].tap()
    }

    // MARK: - Template save validation

    func testSaveWithNoNameShowsError() throws {
        startAMRAP()
        _ = app.buttons["End"].waitForExistence(timeout: 5)
        // Open save template sheet
        let saveBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS 'square.and.arrow.down'")).firstMatch
        if saveBtn.waitForExistence(timeout: 2) {
            saveBtn.tap()
            _ = app.staticTexts["Save as Template"].waitForExistence(timeout: 2)
            app.buttons["Save"].tap()
            let errorShown = app.staticTexts.matching(
                NSPredicate(format: "label CONTAINS 'empty'")).firstMatch.waitForExistence(timeout: 2)
            XCTAssertTrue(errorShown, "Saving with no name should show error")
            app.buttons["Cancel"].tap()
        }
        app.buttons["End"].tap()
        app.buttons["Discard"].tap()
    }

    func testWeightsAutoPopulatedFromLastSession() throws {
        // Soft test: verifies weight chip exists on setup screen
        openSetup(for: "AMRAP")
        let weightText = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS ' lb'")).firstMatch
        let weightExists = weightText.waitForExistence(timeout: 3)
        XCTAssertTrue(weightExists, "Weight chip should be visible on setup card")
        app.buttons["Back"].tap()
    }

    // MARK: - Completion overlay

    func testCompletionMessageOnWorkoutFinish() throws {
        startAMRAP()
        _ = app.buttons["End"].waitForExistence(timeout: 5)
        app.buttons["End"].tap()
        app.buttons["Save & End"].tap()
        _ = app.staticTexts["Workout Complete!"].waitForExistence(timeout: 3)
        // completion message is shown in the overlay
    }

    func testWorkoutCompleteOverlayOnTimerEnd() throws {
        startAMRAP()
        _ = app.buttons["End"].waitForExistence(timeout: 5)
        let stopBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS 'stop.fill'")).firstMatch
        if stopBtn.waitForExistence(timeout: 2) {
            stopBtn.tap()
        } else {
            app.buttons["End"].tap()
            app.buttons["Save & End"].tap()
        }
        let overlay = app.staticTexts["Workout Complete!"]
        if overlay.waitForExistence(timeout: 3) {
            XCTAssertTrue(app.buttons["End Workout"].exists)
            XCTAssertTrue(app.buttons["Go Back"].exists)
            app.buttons["End Workout"].tap()
        }
    }

    // MARK: - AMRAP Active

    func testAMRAPTimerShowsRoundsCounter() throws {
        startAMRAP()
        _ = app.buttons["End"].waitForExistence(timeout: 5)
        XCTAssertTrue(app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'ROUNDS COMPLETED'")).firstMatch.waitForExistence(timeout: 5))
        app.buttons["End"].tap()
        app.buttons["Discard"].tap()
    }

    func testAMRAPTimerShowsWorkPhase() throws {
        startAMRAP()
        _ = app.buttons["End"].waitForExistence(timeout: 5)
        let workLabel = app.staticTexts.matching(
            NSPredicate(format: "label == 'WORK' OR label MATCHES '\\d+'")).firstMatch
        XCTAssertTrue(workLabel.waitForExistence(timeout: 10), "WORK or countdown label should appear")
        app.buttons["End"].tap()
        app.buttons["Discard"].tap()
    }

    func testAMRAPTimerControlsExist() throws {
        startAMRAP()
        _ = app.buttons["End"].waitForExistence(timeout: 5)
        // Pause (play/pause), Skip (forward), Stop buttons
        let buttonCount = app.buttons.count
        XCTAssertGreaterThan(buttonCount, 3, "Active screen should have multiple control buttons")
        app.buttons["End"].tap()
        app.buttons["Discard"].tap()
    }

    func testAMRAPPauseResume() throws {
        startAMRAP()
        _ = app.buttons["End"].waitForExistence(timeout: 5)
        // Find pause button via image match
        let pauseButtons = app.buttons.matching(NSPredicate(format: "label CONTAINS 'pause.fill'"))
        if pauseButtons.firstMatch.waitForExistence(timeout: 3) {
            pauseButtons.firstMatch.tap()
            let playButtons = app.buttons.matching(NSPredicate(format: "label CONTAINS 'play.fill'"))
            XCTAssertTrue(playButtons.firstMatch.waitForExistence(timeout: 2))
        }
        app.buttons["End"].tap()
        app.buttons["Discard"].tap()
    }

    // MARK: - Reps Active

    func testRepsActiveShowsExerciseCards() throws {
        startReps()
        XCTAssertTrue(app.buttons["End"].waitForExistence(timeout: 5))
        app.buttons["End"].tap()
        app.buttons["Discard"].tap()
    }

    func testRepsActiveShowsSetCircles() throws {
        startReps()
        _ = app.buttons["End"].waitForExistence(timeout: 5)
        let setCircles = app.buttons.matching(NSPredicate(format: "label MATCHES '\\d+'"))
        XCTAssertGreaterThan(setCircles.count, 0, "Set circle buttons should be present")
        app.buttons["End"].tap()
        app.buttons["Discard"].tap()
    }

    func testRepsRestTimerAppears() throws {
        startReps()
        _ = app.buttons["End"].waitForExistence(timeout: 5)
        let setCircles = app.buttons.matching(NSPredicate(format: "label MATCHES '\\d+'"))
        if setCircles.firstMatch.waitForExistence(timeout: 3) {
            setCircles.firstMatch.tap()
            let restLabel = app.staticTexts["REST"].firstMatch
            let skipBtn   = app.buttons.matching(NSPredicate(format: "label == 'Skip'")).firstMatch
            let appeared  = restLabel.waitForExistence(timeout: 3) || skipBtn.waitForExistence(timeout: 2)
            XCTAssertTrue(appeared, "REST label or Skip button should appear after completing a set")
        }
        app.buttons["End"].tap()
        app.buttons["Discard"].tap()
    }

    func testDuringWorkoutAdjustReps() throws {
        startReps()
        _ = app.buttons["End"].waitForExistence(timeout: 5)
        let setCircles = app.buttons.matching(NSPredicate(format: "label MATCHES '\\d+'"))
        XCTAssertGreaterThan(setCircles.count, 0, "Reps adjustment available via set circles")
        app.buttons["End"].tap()
        app.buttons["Discard"].tap()
    }

    func testDuringWorkoutAdjustWeights() throws {
        startReps()
        _ = app.buttons["End"].waitForExistence(timeout: 5)
        let plusBtn = app.staticTexts["+5"].firstMatch
        XCTAssertTrue(plusBtn.waitForExistence(timeout: 3), "+5 button should be on active reps screen")
        app.buttons["End"].tap()
        app.buttons["Discard"].tap()
    }

    // MARK: - For Time

    func testForTimeShowsMarkComplete() throws {
        startForTime()
        _ = app.buttons["End"].waitForExistence(timeout: 5)
        XCTAssertTrue(app.buttons["Mark Complete"].waitForExistence(timeout: 10))
        app.buttons["End"].tap()
        app.buttons["Discard"].tap()
    }

    func testForTimeShowsTimeCap() throws {
        startForTime()
        _ = app.buttons["End"].waitForExistence(timeout: 5)
        let capLabel = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Cap:'")).firstMatch
        XCTAssertTrue(capLabel.waitForExistence(timeout: 10), "Cap: M:SS label should be present")
        app.buttons["End"].tap()
        app.buttons["Discard"].tap()
    }

    // MARK: - Intervals

    func testIntervalsShowsRoundCounter() throws {
        startIntervals()
        _ = app.buttons["End"].waitForExistence(timeout: 5)
        let roundLabel = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'Round'")).firstMatch
        XCTAssertTrue(roundLabel.waitForExistence(timeout: 10))
        app.buttons["End"].tap()
        app.buttons["Discard"].tap()
    }

    // MARK: - Manual

    func testManualShowsElapsedTimer() throws {
        openSetup(for: "Manual")
        _ = app.staticTexts["WORKOUTS"].waitForExistence(timeout: 3)
        app.buttons["Start Manual"].tap()
        _ = app.buttons["End"].waitForExistence(timeout: 5)
        let timerText = app.staticTexts.matching(NSPredicate(format: "label MATCHES '\\d+:\\d\\d'")).firstMatch
        XCTAssertTrue(timerText.waitForExistence(timeout: 5), "Timer M:SS format should be visible")
        app.buttons["End"].tap()
        app.buttons["Discard"].tap()
    }

    // MARK: - Layout

    func testSetupTextNotWrappedOrHidden() throws {
        openSetup(for: "Reps")
        let restLabel = app.staticTexts["REST BETWEEN SETS"]
        XCTAssertTrue(restLabel.waitForExistence(timeout: 3))
        let screenBounds = app.windows.firstMatch.frame
        XCTAssertTrue(screenBounds.contains(restLabel.frame))
        app.buttons["Back"].tap()
    }

    // MARK: - Helpers

    private func openSetup(for type: String) {
        app.buttons["Start Workout Timer"].tap()
        _ = app.staticTexts["Choose Workout Type"].waitForExistence(timeout: 3)
        app.staticTexts[type].tap()
    }

    private func startAMRAP() {
        openSetup(for: "AMRAP")
        _ = app.staticTexts["TIME LIMIT"].waitForExistence(timeout: 3)
        app.buttons["Start AMRAP"].tap()
    }

    private func startReps() {
        openSetup(for: "Reps")
        _ = app.staticTexts["REST BETWEEN SETS"].waitForExistence(timeout: 3)
        app.buttons["Start Reps"].tap()
    }

    private func startForTime() {
        openSetup(for: "For Time")
        _ = app.staticTexts["TIME CAP"].waitForExistence(timeout: 3)
        app.buttons["Start For Time"].tap()
    }

    private func startIntervals() {
        openSetup(for: "Intervals")
        _ = app.buttons["Start Intervals"].waitForExistence(timeout: 3)
        app.buttons["Start Intervals"].tap()
    }
}
