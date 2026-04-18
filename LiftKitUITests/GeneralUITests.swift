import XCTest

final class GeneralUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testAllTabsNavigate() throws {
        let tabs = ["Workout", "History", "Progress", "Settings"]
        for tab in tabs {
            app.tabBars.buttons[tab].tap()
            XCTAssertTrue(app.navigationBars[tab].waitForExistence(timeout: 3) ||
                          app.buttons["Start Workout Timer"].waitForExistence(timeout: 1),
                          "\(tab) tab should navigate")
        }
    }

    func testSettingsToggles() throws {
        app.tabBars.buttons["Settings"].tap()
        _ = app.navigationBars["Settings"].waitForExistence(timeout: 3)
        let soundToggle = app.switches["Timer Sounds"]
        if soundToggle.waitForExistence(timeout: 2) {
            soundToggle.tap()
            soundToggle.tap() // Toggle back
        }
    }

    func testProgressTabLoads() throws {
        app.tabBars.buttons["Progress"].tap()
        _ = app.navigationBars["Progress"].waitForExistence(timeout: 3)
        // Verify no crash and basic structure
        XCTAssertTrue(app.navigationBars["Progress"].exists)
    }

    func testSettingsVersionLabel() throws {
        app.tabBars.buttons["Settings"].tap()
        _ = app.navigationBars["Settings"].waitForExistence(timeout: 3)
        let versionLabel = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS '1.'")).firstMatch
        XCTAssertTrue(versionLabel.waitForExistence(timeout: 3),
                      "Version label should be present in settings")
    }

    func testLoginSheetDismisses() throws {
        let loginBtn = app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'Log In'")).firstMatch
        if loginBtn.waitForExistence(timeout: 3) {
            loginBtn.tap()
            _ = app.staticTexts["LiftKit"].waitForExistence(timeout: 3)
            let continueBtn = app.buttons.matching(
                NSPredicate(format: "label CONTAINS 'Continue without'")).firstMatch
            if continueBtn.waitForExistence(timeout: 2) {
                continueBtn.tap()
            } else {
                app.buttons.matching(NSPredicate(format: "label == 'xmark'")).firstMatch.tap()
            }
            XCTAssertTrue(app.buttons["Start Workout Timer"].waitForExistence(timeout: 3))
        }
    }

    func testTypePickerGridLayout() throws {
        app.buttons["Start Workout Timer"].tap()
        _ = app.staticTexts["Choose Workout Type"].waitForExistence(timeout: 3)
        let cardCount = app.staticTexts.matching(
            NSPredicate(format: "label IN {'AMRAP','EMOM','For Time','Intervals','Reps','Manual'}")).count
        XCTAssertEqual(cardCount, 6, "All 6 workout type cards should be visible")
        app.buttons["Cancel"].tap()
    }
}
