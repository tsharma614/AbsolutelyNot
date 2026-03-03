import XCTest
@testable import AbsolutelyNot

final class GameStateTests: XCTestCase {

    func testEmptyState() {
        let state = GameState.empty
        XCTAssertTrue(state.players.isEmpty)
        XCTAssertNil(state.currentCard)
        XCTAssertEqual(state.phase, .setup)
        XCTAssertFalse(state.isGameOver)
    }

    func testIsGameOver() {
        var state = GameState.empty
        state.phase = .gameOver
        XCTAssertTrue(state.isGameOver)
    }

    func testCurrentPlayer() {
        var state = GameState.empty
        state.players = [
            Player(name: "A", emoji: "😀", isAI: false, pebbles: 5),
            Player(name: "B", emoji: "🤖", isAI: true, pebbles: 5),
        ]
        state.currentPlayerIndex = 1
        XCTAssertEqual(state.currentPlayer?.name, "B")
    }

    func testCurrentPlayerOutOfBounds() {
        var state = GameState.empty
        state.currentPlayerIndex = 5
        XCTAssertNil(state.currentPlayer)
    }

    func testCardsRemaining() {
        var state = GameState.empty
        state.drawPile = [Card(value: 5), Card(value: 10)]
        XCTAssertEqual(state.cardsRemaining, 2)
    }

    func testGamePhaseEquality() {
        XCTAssertEqual(GamePhase.setup, GamePhase.setup)
        XCTAssertEqual(GamePhase.playerTurn(playerIndex: 0), GamePhase.playerTurn(playerIndex: 0))
        XCTAssertNotEqual(GamePhase.playerTurn(playerIndex: 0), GamePhase.playerTurn(playerIndex: 1))
        XCTAssertEqual(GamePhase.gameOver, GamePhase.gameOver)
    }

    func testGameStateCodable() throws {
        var state = GameState.empty
        state.players = [Player(name: "Test", emoji: "🎃", isAI: false, pebbles: 11)]
        state.currentCard = Card(value: 15)
        state.phase = .playerTurn(playerIndex: 0)

        let data = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(GameState.self, from: data)

        XCTAssertEqual(decoded.players.count, 1)
        XCTAssertEqual(decoded.currentCard?.value, 15)
        XCTAssertEqual(decoded.phase, .playerTurn(playerIndex: 0))
    }
}
