import XCTest
@testable import AbsolutelyNot

@MainActor
final class GamePlayViewModelTests: XCTestCase {

    private func makeViewModel(allHuman: Bool = true) -> GamePlayViewModel {
        let config = GameConfig(
            playerCount: 3,
            playerNames: ["Alice", "Bob", "Carol"],
            playerEmojis: ["😀", "🤖", "🎃"],
            aiFlags: allHuman ? [false, false, false] : [false, true, true]
        )
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_log_\(UUID().uuidString).txt")
        let logger = GameLogger(fileURL: tempURL)
        return GamePlayViewModel(config: config, logger: logger)
    }

    func testInitialState() {
        let vm = makeViewModel()
        XCTAssertFalse(vm.isGameOver)
        XCTAssertNotNil(vm.currentCard)
        XCTAssertEqual(vm.pebblesOnCard, 0)
        XCTAssertEqual(vm.currentPlayerIndex, 0)
    }

    func testCanTakeOnHumanTurn() {
        let vm = makeViewModel()
        XCTAssertTrue(vm.canTake)
    }

    func testCanPassOnHumanTurn() {
        let vm = makeViewModel()
        XCTAssertTrue(vm.canPass)
    }

    func testTakeCard() {
        let vm = makeViewModel()
        let cardBefore = vm.currentCard
        vm.takeCard()

        // Card should be in player 0's hand
        XCTAssertTrue(vm.players[0].collectedCards.contains(where: { $0 == cardBefore }))
        // Turn advances to next player, who must draw
        XCTAssertEqual(vm.currentPlayerIndex, 1)
        XCTAssertTrue(vm.isAwaitingDraw)
        XCTAssertTrue(vm.humanShouldDraw) // all human in this test
    }

    func testDrawNextCard() {
        let vm = makeViewModel()
        vm.takeCard()
        // Next player (1) must draw
        XCTAssertTrue(vm.isAwaitingDraw)
        XCTAssertNil(vm.currentCard)

        vm.drawNextCard()
        XCTAssertFalse(vm.isAwaitingDraw)
        XCTAssertNotNil(vm.currentCard)
        XCTAssertEqual(vm.currentPlayerIndex, 1) // player 1 now decides
    }

    func testPassCard() {
        let vm = makeViewModel()
        let pebblesBefore = vm.players[0].pebbles
        vm.passCard()

        XCTAssertEqual(vm.players[0].pebbles, pebblesBefore - 1)
        XCTAssertEqual(vm.pebblesOnCard, 1)
        XCTAssertEqual(vm.currentPlayerIndex, 1) // Advances
    }

    func testPassAndPlayInterstitial() {
        let vm = makeViewModel(allHuman: true)
        vm.passCard() // Player 0 passes, turn goes to player 1

        // Interstitial should be triggered (after delay)
        let exp = expectation(description: "interstitial")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertTrue(vm.showInterstitial)
            XCTAssertEqual(vm.interstitialPlayerName, "Bob")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2.0)
    }

    func testDismissInterstitial() {
        let vm = makeViewModel()
        vm.showInterstitial = true
        vm.dismissInterstitial()
        XCTAssertFalse(vm.showInterstitial)
    }

    func testCannotPassWithZeroPebbles() {
        let state = GameState(
            players: [
                Player(name: "Broke", emoji: "😢", isAI: false, pebbles: 0),
                Player(name: "Rich", emoji: "🤑", isAI: false, pebbles: 11),
                Player(name: "Also Rich", emoji: "💰", isAI: false, pebbles: 11),
            ],
            drawPile: [Card(value: 10)],
            currentCard: Card(value: 20),
            pebblesOnCard: 0,
            currentPlayerIndex: 0,
            removedCards: [],
            phase: .playerTurn(playerIndex: 0)
        )
        let engine = GameEngine(state: state)
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_log_\(UUID().uuidString).txt")
        let vm = GamePlayViewModel(engine: engine, logger: GameLogger(fileURL: tempURL))

        XCTAssertFalse(vm.canPass)
        XCTAssertTrue(vm.canTake)
    }
}
