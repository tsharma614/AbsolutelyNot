import XCTest
@testable import AbsolutelyNot

final class GameEngineTests: XCTestCase {

    private func makeConfig(playerCount: Int = 3) -> GameConfig {
        GameConfig(
            playerCount: playerCount,
            playerNames: Array(["Alice", "Bob", "Carol", "Dave", "Eve", "Frank", "Grace"].prefix(playerCount)),
            playerEmojis: Array(["😀", "🤖", "🎃", "🦊", "🐸", "🌵", "🎸"].prefix(playerCount)),
            aiFlags: Array(repeating: false, count: playerCount)
        )
    }

    func testInitialState() {
        let engine = GameEngine(config: makeConfig())
        XCTAssertEqual(engine.state.players.count, 3)
        XCTAssertEqual(engine.state.drawPile.count, 23) // 33 - 9 removed - 1 face-up
        XCTAssertNotNil(engine.state.currentCard)
        XCTAssertEqual(engine.state.pebblesOnCard, 0)
        XCTAssertEqual(engine.state.removedCards.count, 9)
        XCTAssertEqual(engine.state.currentPlayerIndex, 0)
    }

    func testInitialPebbles3Players() {
        let engine = GameEngine(config: makeConfig(playerCount: 3))
        for player in engine.state.players {
            XCTAssertEqual(player.pebbles, 11)
        }
    }

    func testInitialPebbles6Players() {
        let engine = GameEngine(config: makeConfig(playerCount: 6))
        for player in engine.state.players {
            XCTAssertEqual(player.pebbles, 9)
        }
    }

    func testInitialPebbles7Players() {
        let engine = GameEngine(config: makeConfig(playerCount: 7))
        for player in engine.state.players {
            XCTAssertEqual(player.pebbles, 7)
        }
    }

    func testTakeCardAddsToPlayer() {
        let engine = GameEngine(config: makeConfig())
        let card = engine.state.currentCard!
        engine.takeCard()

        XCTAssertTrue(engine.state.players[0].collectedCards.contains(card))
    }

    func testTakeCardGivesPebbles() {
        let engine = GameEngine(config: makeConfig())
        // Put some pebbles on card first
        engine.passCard() // player 0 passes → player 1
        engine.passCard() // player 1 passes → player 2
        engine.passCard() // player 2 passes → player 0

        // Now player 0's turn, 3 pebbles on card
        XCTAssertEqual(engine.state.pebblesOnCard, 3)
        let pebblesBefore = engine.state.players[0].pebbles
        engine.takeCard()

        // Player 0 gets card + 3 pebbles
        XCTAssertEqual(engine.state.players[0].pebbles, pebblesBefore + 3)
        XCTAssertEqual(engine.state.pebblesOnCard, 0)
    }

    func testTakeAdvancesToNextPlayerAwaitingDraw() {
        let engine = GameEngine(config: makeConfig())
        XCTAssertEqual(engine.state.currentPlayerIndex, 0)
        engine.takeCard()
        // After taking, advances to next player who must draw
        XCTAssertEqual(engine.state.currentPlayerIndex, 1)
        XCTAssertEqual(engine.state.phase, .awaitingDraw(playerIndex: 1))
        XCTAssertNil(engine.state.currentCard) // card cleared until draw
    }

    func testDrawNextCardFlipsCard() {
        let engine = GameEngine(config: makeConfig())
        engine.takeCard()
        // Player 1 must draw
        XCTAssertEqual(engine.state.phase, .awaitingDraw(playerIndex: 1))
        engine.drawNextCard()
        // After draw, card is face-up and player 1 decides
        XCTAssertNotNil(engine.state.currentCard)
        XCTAssertEqual(engine.state.currentPlayerIndex, 1)
        XCTAssertEqual(engine.state.phase, .playerTurn(playerIndex: 1))
    }

    func testPassAdvancesTurn() {
        let engine = GameEngine(config: makeConfig())
        XCTAssertEqual(engine.state.currentPlayerIndex, 0)
        engine.passCard()
        XCTAssertEqual(engine.state.currentPlayerIndex, 1)
    }

    func testPassDecrementsPebbles() {
        let engine = GameEngine(config: makeConfig())
        let pebblesBefore = engine.state.players[0].pebbles
        engine.passCard()
        XCTAssertEqual(engine.state.players[0].pebbles, pebblesBefore - 1)
    }

    func testPassIncrementsCardPebbles() {
        let engine = GameEngine(config: makeConfig())
        XCTAssertEqual(engine.state.pebblesOnCard, 0)
        engine.passCard()
        XCTAssertEqual(engine.state.pebblesOnCard, 1)
    }

    func testPassWrapsAround() {
        let engine = GameEngine(config: makeConfig())
        engine.passCard() // 0 -> 1
        engine.passCard() // 1 -> 2
        engine.passCard() // 2 -> 0
        XCTAssertEqual(engine.state.currentPlayerIndex, 0)
    }

    func testZeroPebblesCannotPass() {
        // Create a state where player has 0 pebbles
        var state = GameState(
            players: [
                Player(name: "Broke", emoji: "😢", isAI: false, pebbles: 0),
                Player(name: "Rich", emoji: "🤑", isAI: false, pebbles: 11),
            ],
            drawPile: [Card(value: 10)],
            currentCard: Card(value: 20),
            pebblesOnCard: 0,
            currentPlayerIndex: 0,
            removedCards: [],
            phase: .playerTurn(playerIndex: 0)
        )
        let engine = GameEngine(state: state)
        XCTAssertFalse(engine.state.players[0].canPass)

        // Pass should be no-op
        engine.passCard()
        XCTAssertEqual(engine.state.currentPlayerIndex, 0) // Didn't advance
    }

    func testGameEndsWhenDrawPileEmpty() {
        var state = GameState(
            players: [
                Player(name: "A", emoji: "😀", isAI: false, pebbles: 5),
                Player(name: "B", emoji: "🤖", isAI: false, pebbles: 5),
            ],
            drawPile: [], // empty
            currentCard: Card(value: 15),
            pebblesOnCard: 2,
            currentPlayerIndex: 0,
            removedCards: [],
            phase: .playerTurn(playerIndex: 0)
        )
        let engine = GameEngine(state: state)
        engine.takeCard()

        XCTAssertTrue(engine.state.isGameOver)
        XCTAssertEqual(engine.state.phase, .gameOver)
    }

    func testGameContinuesWithCardsInDraw() {
        let engine = GameEngine(config: makeConfig())
        engine.takeCard()
        XCTAssertFalse(engine.state.isGameOver)
        // Card is nil until drawNextCard is called
        XCTAssertNil(engine.state.currentCard)
        engine.drawNextCard()
        XCTAssertNotNil(engine.state.currentCard)
        XCTAssertFalse(engine.state.isGameOver)
    }

    func testRankedResults() {
        var state = GameState(
            players: [
                Player(name: "A", emoji: "😀", isAI: false, pebbles: 5),
                Player(name: "B", emoji: "🤖", isAI: false, pebbles: 3),
            ],
            drawPile: [],
            currentCard: nil,
            pebblesOnCard: 0,
            currentPlayerIndex: 0,
            removedCards: [],
            phase: .gameOver
        )
        state.players[0].collectedCards = [Card(value: 20)] // 20 - 5 = 15
        state.players[1].collectedCards = [Card(value: 10)] // 10 - 3 = 7

        let engine = GameEngine(state: state)
        let results = engine.rankedResults()

        XCTAssertEqual(results[0].player.name, "B") // Lower score = winner
        XCTAssertEqual(results[0].score, 7)
        XCTAssertEqual(results[1].player.name, "A")
        XCTAssertEqual(results[1].score, 15)
    }

    func testTotalCardsInGame() {
        let engine = GameEngine(config: makeConfig())
        let totalCards = engine.state.drawPile.count + 1 + engine.state.removedCards.count // draw + face-up + removed
        XCTAssertEqual(totalCards, 33)
    }
}
