import XCTest

final class GamePlayUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()

        // Navigate to game play
        let startButton = app.buttons["startGameButton"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 3))
        startButton.tap()

        // Wait for game to load
        let takeButton = app.buttons["takeButton"]
        XCTAssertTrue(takeButton.waitForExistence(timeout: 3))
    }

    func testTakeButtonExists() {
        XCTAssertTrue(app.buttons["takeButton"].exists)
    }

    func testPassButtonExists() {
        XCTAssertTrue(app.buttons["passButton"].exists)
    }

    func testTakeButtonTappable() {
        let takeButton = app.buttons["takeButton"]
        XCTAssertTrue(takeButton.isEnabled)
        takeButton.tap()
        // Should still be on game screen (same player takes again)
        XCTAssertTrue(app.buttons["takeButton"].waitForExistence(timeout: 3))
    }

    func testPassButtonTappable() {
        let passButton = app.buttons["passButton"]
        XCTAssertTrue(passButton.isEnabled)
        passButton.tap()
        // Game continues (AI turns may auto-play)
        XCTAssertTrue(app.buttons["takeButton"].waitForExistence(timeout: 5))
    }
}
