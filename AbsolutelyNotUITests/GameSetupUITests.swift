import XCTest

final class GameSetupUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    func testSetupScreenAppears() {
        XCTAssertTrue(app.staticTexts["Absolutely Not!"].exists)
    }

    func testStartButtonExists() {
        XCTAssertTrue(app.buttons["startGameButton"].exists)
    }

    func testPlayerNameFieldsExist() {
        XCTAssertTrue(app.textFields["playerName0"].exists)
        XCTAssertTrue(app.textFields["playerName1"].exists)
        XCTAssertTrue(app.textFields["playerName2"].exists)
    }

    func testStartGameNavigation() {
        // Default setup has 1 human + 2 AI, should be valid
        let startButton = app.buttons["startGameButton"]
        XCTAssertTrue(startButton.isEnabled)
        startButton.tap()

        // Should navigate to game play
        let takeButton = app.buttons["takeButton"]
        XCTAssertTrue(takeButton.waitForExistence(timeout: 3))
    }
}
