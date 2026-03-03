import XCTest
@testable import AbsolutelyNot

final class GameSetupViewModelTests: XCTestCase {

    func testDefaultState() {
        let vm = GameSetupViewModel()
        XCTAssertEqual(vm.playerCount, 3)
        XCTAssertEqual(vm.playerNames.count, 3)
        XCTAssertEqual(vm.isAI.count, 3)
    }

    func testIsValidWithOneHuman() {
        let vm = GameSetupViewModel()
        vm.isAI = [false, true, true]
        XCTAssertTrue(vm.isValid)
    }

    func testInvalidAllAI() {
        let vm = GameSetupViewModel()
        vm.isAI = [true, true, true]
        XCTAssertFalse(vm.isValid)
    }

    func testInvalidEmptyName() {
        let vm = GameSetupViewModel()
        vm.playerNames[0] = "   "
        XCTAssertFalse(vm.isValid)
    }

    func testPlayerCountAdjustsArrays() {
        let vm = GameSetupViewModel()
        vm.playerCount = 5
        XCTAssertEqual(vm.playerNames.count, 5)
        XCTAssertEqual(vm.playerEmojis.count, 5)
        XCTAssertEqual(vm.isAI.count, 5)
    }

    func testPebblesPerPlayer() {
        let vm = GameSetupViewModel()
        vm.playerCount = 3
        XCTAssertEqual(vm.pebblesPerPlayer, 11)
        vm.playerCount = 6
        XCTAssertEqual(vm.pebblesPerPlayer, 9)
        vm.playerCount = 7
        XCTAssertEqual(vm.pebblesPerPlayer, 7)
    }

    func testBuildConfig() {
        let vm = GameSetupViewModel()
        vm.playerCount = 4
        let config = vm.buildConfig()
        XCTAssertEqual(config.playerCount, 4)
        XCTAssertEqual(config.playerNames.count, 4)
        XCTAssertTrue(config.isValid)
    }
}
