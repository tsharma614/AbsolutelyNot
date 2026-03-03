import XCTest
@testable import AbsolutelyNot

final class GameLoggerTests: XCTestCase {
    private var logger: GameLogger!
    private var testFileURL: URL!

    override func setUp() {
        super.setUp()
        let tempDir = FileManager.default.temporaryDirectory
        testFileURL = tempDir.appendingPathComponent("test_game_log_\(UUID().uuidString).txt")
        logger = GameLogger(fileURL: testFileURL)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: testFileURL)
        super.tearDown()
    }

    func testLogCreatesFile() {
        logger.log("Test message", context: "Test")
        // Wait for async write
        let exp = expectation(description: "log write")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { exp.fulfill() }
        wait(for: [exp], timeout: 2.0)

        XCTAssertTrue(FileManager.default.fileExists(atPath: testFileURL.path))
    }

    func testLogContent() {
        logger.log("Hello world", context: "Test")
        let exp = expectation(description: "log write")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { exp.fulfill() }
        wait(for: [exp], timeout: 2.0)

        let content = logger.readLog()
        XCTAssertTrue(content.contains("[Test] Hello world"))
    }

    func testLogAppends() {
        logger.log("First", context: "A")
        logger.log("Second", context: "B")
        let exp = expectation(description: "log write")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { exp.fulfill() }
        wait(for: [exp], timeout: 2.0)

        let content = logger.readLog()
        XCTAssertTrue(content.contains("First"))
        XCTAssertTrue(content.contains("Second"))
    }

    func testClearLog() {
        logger.log("Something", context: "Test")
        let exp1 = expectation(description: "log write")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { exp1.fulfill() }
        wait(for: [exp1], timeout: 2.0)

        logger.clearLog()
        let exp2 = expectation(description: "log clear")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { exp2.fulfill() }
        wait(for: [exp2], timeout: 2.0)

        let content = logger.readLog()
        XCTAssertTrue(content.isEmpty)
    }

    func testReadEmptyLog() {
        let content = logger.readLog()
        XCTAssertTrue(content.isEmpty)
    }
}
