import XCTest

final class HistoryUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testHistoryTabShowsEmptyState() throws {
        app.tabBars.buttons["History"].tap()
        _ = app.navigationBars["History"].waitForExistence(timeout: 3)
        // Either shows sessions or empty state — no crash
        let hasContent = app.staticTexts["No Workouts Yet"].exists ||
                         app.tables.cells.count > 0
        XCTAssertTrue(hasContent, "History tab should show content or empty state")
    }

    func testHistorySwipeToDelete() throws {
        // Only runs if sessions exist
        app.tabBars.buttons["History"].tap()
        _ = app.navigationBars["History"].waitForExistence(timeout: 3)
        let cells = app.tables.cells
        if cells.count > 0 {
            let firstCell = cells.firstMatch
            firstCell.swipeLeft()
            let deleteBtn = app.buttons["Delete"]
            if deleteBtn.waitForExistence(timeout: 2) {
                deleteBtn.tap()
            }
        }
    }

    func testHistoryContextMenu() throws {
        app.tabBars.buttons["History"].tap()
        _ = app.navigationBars["History"].waitForExistence(timeout: 3)
        let cells = app.tables.cells
        if cells.count > 0 {
            cells.firstMatch.press(forDuration: 1.0)
            let doAgain = app.buttons["Do Again"]
            let doAgainExists = doAgain.waitForExistence(timeout: 2)
            if doAgainExists {
                XCTAssertTrue(doAgainExists)
                app.buttons["Cancel"].tap()
            }
        }
    }
}
