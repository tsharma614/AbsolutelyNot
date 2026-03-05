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

    private func makePassAndPlayVM(
        players: [Player],
        currentCard: Card,
        drawPile: [Card],
        pebblesOnCard: Int = 0,
        currentPlayerIndex: Int = 0
    ) -> GamePlayViewModel {
        let phase: GamePhase
        if players[currentPlayerIndex].isAI {
            phase = .aiThinking(playerIndex: currentPlayerIndex)
        } else {
            phase = .playerTurn(playerIndex: currentPlayerIndex)
        }
        let state = GameState(
            players: players,
            drawPile: drawPile,
            currentCard: currentCard,
            pebblesOnCard: pebblesOnCard,
            currentPlayerIndex: currentPlayerIndex,
            removedCards: [],
            phase: phase
        )
        let engine = GameEngine(state: state)
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_log_\(UUID().uuidString).txt")
        return GamePlayViewModel(engine: engine, logger: GameLogger(fileURL: tempURL), isPassAndPlay: true)
    }

    private func makeDeck(_ count: Int, startingAt start: Int = 3) -> [Card] {
        (start..<(start + count)).map { Card(value: $0) }
    }

    // MARK: - Existing tests (updated for initial interstitial)

    func testInitialState() {
        let vm = makeViewModel()
        XCTAssertFalse(vm.isGameOver)
        XCTAssertNotNil(vm.currentCard)
        XCTAssertEqual(vm.pebblesOnCard, 0)
        XCTAssertEqual(vm.currentPlayerIndex, 0)
    }

    func testCanTakeOnHumanTurn() {
        let vm = makeViewModel()
        vm.dismissInterstitial() // dismiss initial pass-and-play interstitial
        XCTAssertTrue(vm.canTake)
    }

    func testCanPassOnHumanTurn() {
        let vm = makeViewModel()
        vm.dismissInterstitial()
        XCTAssertTrue(vm.canPass)
    }

    func testTakeCard() {
        let vm = makeViewModel()
        vm.dismissInterstitial()
        let cardBefore = vm.currentCard
        vm.takeCard()

        // Card should be in player 0's hand
        XCTAssertTrue(vm.players[0].collectedCards.contains(where: { $0 == cardBefore }))
        // Turn advances to next player, who must draw
        XCTAssertEqual(vm.currentPlayerIndex, 1)
        XCTAssertTrue(vm.isAwaitingDraw)

        // In pass-and-play, interstitial fires for the drawer — dismiss to check humanShouldDraw
        vm.dismissInterstitial()
        XCTAssertTrue(vm.humanShouldDraw)
    }

    func testDrawNextCard() {
        let vm = makeViewModel()
        vm.dismissInterstitial()
        vm.takeCard()
        // Next player (1) must draw
        XCTAssertTrue(vm.isAwaitingDraw)
        XCTAssertNil(vm.currentCard)

        vm.dismissInterstitial() // dismiss draw interstitial
        vm.drawNextCard()
        XCTAssertFalse(vm.isAwaitingDraw)
        XCTAssertNotNil(vm.currentCard)
        XCTAssertEqual(vm.currentPlayerIndex, 1) // player 1 now decides
    }

    func testPassCard() {
        let vm = makeViewModel()
        vm.dismissInterstitial()
        let pebblesBefore = vm.players[0].pebbles
        vm.passCard()

        XCTAssertEqual(vm.players[0].pebbles, pebblesBefore - 1)
        XCTAssertEqual(vm.pebblesOnCard, 1)
        XCTAssertEqual(vm.currentPlayerIndex, 1) // Advances
    }

    func testPassAndPlayInterstitial() {
        let vm = makeViewModel(allHuman: true)
        vm.dismissInterstitial() // dismiss initial interstitial for Player 0
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

    // MARK: - Pass-and-play: AI pass to human

    func testPassAndPlayAIPassToHumanShowsInterstitial() {
        // H0, AI1, H2 — Human passes, AI passes (card 35 too expensive), lands on H2
        let players = [
            Player(name: "H0", emoji: "🧑", isAI: false, pebbles: 11),
            Player(name: "AI1", emoji: "🤖", isAI: true, pebbles: 11),
            Player(name: "H2", emoji: "🧑", isAI: false, pebbles: 11),
        ]
        let vm = makePassAndPlayVM(players: players, currentCard: Card(value: 35), drawPile: makeDeck(10))

        // Human 0 passes -> AI1's turn
        vm.passCard()

        let exp = expectation(description: "AI passes then interstitial for H2")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            XCTAssertEqual(vm.currentPlayerIndex, 2)
            XCTAssertFalse(vm.turnRevealed)
            XCTAssertEqual(vm.interstitialPlayerName, "H2")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5.0)
    }

    // MARK: - Pass-and-play: AI take to human draw

    func testPassAndPlayAITakeToHumanDrawShowsInterstitial() {
        // H0, AI1 (0 pebbles = forced take), H2 — Human passes, AI forced-takes, H2 must draw
        let players = [
            Player(name: "H0", emoji: "🧑", isAI: false, pebbles: 11),
            Player(name: "AI1", emoji: "🤖", isAI: true, pebbles: 0),
            Player(name: "H2", emoji: "🧑", isAI: false, pebbles: 11),
        ]
        let vm = makePassAndPlayVM(players: players, currentCard: Card(value: 35), drawPile: makeDeck(10))

        // Human 0 passes -> AI1's turn (forced take since 0 pebbles)
        vm.passCard()

        let exp = expectation(description: "AI takes then interstitial for H2 draw")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            // AI took card, H2 must draw, interstitial should fire
            XCTAssertFalse(vm.turnRevealed)
            XCTAssertEqual(vm.interstitialPlayerName, "H2")
            if case .awaitingDraw(let idx) = vm.phase {
                XCTAssertEqual(idx, 2)
            } else {
                XCTFail("Expected awaitingDraw phase, got \(vm.phase)")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5.0)
    }

    // MARK: - Pass-and-play: initial interstitial

    func testPassAndPlayInitialInterstitial() {
        let vm = makeViewModel(allHuman: true)

        XCTAssertFalse(vm.turnRevealed, "turnRevealed should start false in pass-and-play")
        XCTAssertEqual(vm.interstitialPlayerName, "Alice")

        let exp = expectation(description: "initial interstitial shows")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertTrue(vm.showInterstitial)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2.0)
    }

    // MARK: - Pass-and-play: turnRevealed during handoff

    func testPassAndPlayTurnRevealedFalseDuringHandoff() {
        let players = [
            Player(name: "H0", emoji: "🧑", isAI: false, pebbles: 11),
            Player(name: "H1", emoji: "🧑", isAI: false, pebbles: 11),
            Player(name: "H2", emoji: "🧑", isAI: false, pebbles: 11),
        ]
        let vm = makePassAndPlayVM(players: players, currentCard: Card(value: 10), drawPile: makeDeck(10))

        vm.passCard()
        XCTAssertFalse(vm.turnRevealed, "turnRevealed should be false immediately after handoff")
    }

    // MARK: - Pass-and-play: cannot act while turn not revealed

    func testPassAndPlayCannotActWhileTurnNotRevealed() {
        let players = [
            Player(name: "H0", emoji: "🧑", isAI: false, pebbles: 11),
            Player(name: "H1", emoji: "🧑", isAI: false, pebbles: 11),
            Player(name: "H2", emoji: "🧑", isAI: false, pebbles: 11),
        ]
        let vm = makePassAndPlayVM(players: players, currentCard: Card(value: 10), drawPile: makeDeck(10))

        vm.passCard() // triggers interstitial for H1
        XCTAssertFalse(vm.canTake, "canTake should be false when turn not revealed")
        XCTAssertFalse(vm.canPass, "canPass should be false when turn not revealed")
    }

    // MARK: - Pass-and-play: human pass to human

    func testPassAndPlayHumanPassToHumanShowsInterstitial() {
        let players = [
            Player(name: "H0", emoji: "🧑", isAI: false, pebbles: 11),
            Player(name: "H1", emoji: "🧑", isAI: false, pebbles: 11),
            Player(name: "H2", emoji: "🧑", isAI: false, pebbles: 11),
        ]
        let vm = makePassAndPlayVM(players: players, currentCard: Card(value: 10), drawPile: makeDeck(10))

        vm.passCard()

        let exp = expectation(description: "interstitial for H1")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertTrue(vm.showInterstitial)
            XCTAssertEqual(vm.interstitialPlayerName, "H1")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2.0)
    }

    // MARK: - Pass-and-play: human take to human draw

    func testPassAndPlayHumanTakeToHumanDrawShowsInterstitial() {
        let players = [
            Player(name: "H0", emoji: "🧑", isAI: false, pebbles: 11),
            Player(name: "H1", emoji: "🧑", isAI: false, pebbles: 11),
            Player(name: "H2", emoji: "🧑", isAI: false, pebbles: 11),
        ]
        let vm = makePassAndPlayVM(players: players, currentCard: Card(value: 10), drawPile: makeDeck(10))

        vm.takeCard()

        // H1 must draw, interstitial should fire
        XCTAssertFalse(vm.turnRevealed)
        XCTAssertEqual(vm.interstitialPlayerName, "H1")
        XCTAssertTrue(vm.isAwaitingDraw)
    }

    // MARK: - Single human: no interstitial

    func testSingleHumanNoInterstitial() {
        let vm = makeViewModel(allHuman: false)

        XCTAssertTrue(vm.turnRevealed, "turnRevealed should be true for single-human game")
        XCTAssertFalse(vm.showInterstitial, "showInterstitial should be false for single-human game")
        XCTAssertEqual(vm.interstitialPlayerName, "")
    }

    // MARK: - Pass-and-play: 6 humans + 1 AI

    func testPassAndPlay6Humans1AI() {
        // 7 players, AI at position 3
        var players: [Player] = []
        for i in 0..<7 {
            let isAI = (i == 3)
            players.append(Player(
                name: isAI ? "AI3" : "H\(i)",
                emoji: isAI ? "🤖" : "🧑",
                isAI: isAI,
                pebbles: 7
            ))
        }

        let vm = makePassAndPlayVM(players: players, currentCard: Card(value: 35), drawPile: makeDeck(10), currentPlayerIndex: 2)

        // H2 passes -> AI3's turn. AI3 should pass on card 35.
        vm.passCard()

        let exp = expectation(description: "AI3 passes, interstitial for H4")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            XCTAssertEqual(vm.currentPlayerIndex, 4)
            XCTAssertFalse(vm.turnRevealed)
            XCTAssertEqual(vm.interstitialPlayerName, "H4")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5.0)
    }

    // MARK: - Pass-and-play: 2 humans + 5 AI

    func testPassAndPlay2Humans5AI() {
        // H0, AI1-AI5, H6 — AI chain should pass on card 35 and land on H6
        var players: [Player] = []
        players.append(Player(name: "H0", emoji: "🧑", isAI: false, pebbles: 7))
        for i in 1...5 {
            players.append(Player(name: "AI\(i)", emoji: "🤖", isAI: true, pebbles: 7))
        }
        players.append(Player(name: "H6", emoji: "🧑", isAI: false, pebbles: 7))

        let vm = makePassAndPlayVM(players: players, currentCard: Card(value: 35), drawPile: makeDeck(10))

        // H0 passes -> AI1 -> AI2 -> ... -> AI5 -> H6
        vm.passCard()

        let exp = expectation(description: "AI chain passes, interstitial for H6")
        DispatchQueue.main.asyncAfter(deadline: .now() + 13.0) {
            XCTAssertEqual(vm.currentPlayerIndex, 6)
            XCTAssertFalse(vm.turnRevealed)
            XCTAssertEqual(vm.interstitialPlayerName, "H6")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 16.0)
    }
}
