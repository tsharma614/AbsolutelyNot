import XCTest
@testable import AbsolutelyNot

final class GameMessageTests: XCTestCase {

    func testPlayerActionEncodeDecode() throws {
        let original = GameMessage.playerAction(.take, playerID: "player1")
        let data = try original.encoded()
        let decoded = try GameMessage.decoded(from: data)
        XCTAssertEqual(decoded, original)
    }

    func testPlayerActionPass() throws {
        let original = GameMessage.playerAction(.pass, playerID: "player2")
        let data = try original.encoded()
        let decoded = try GameMessage.decoded(from: data)
        XCTAssertEqual(decoded, original)
    }

    func testLobbyUpdateEncodeDecode() throws {
        let players = [
            LobbyState.LobbyPlayer(id: "1", name: "Alice", emoji: "😀"),
            LobbyState.LobbyPlayer(id: "2", name: "Bob", emoji: "🤖"),
        ]
        let original = GameMessage.lobbyUpdate(.waiting(players: players))
        let data = try original.encoded()
        let decoded = try GameMessage.decoded(from: data)
        XCTAssertEqual(decoded, original)
    }

    func testGameStateEncodeDecode() throws {
        var state = GameState.empty
        state.players = [Player(name: "Test", emoji: "🎃", isAI: false, pebbles: 11)]
        state.currentCard = Card(value: 15)

        let original = GameMessage.gameState(state)
        let data = try original.encoded()
        let decoded = try GameMessage.decoded(from: data)
        XCTAssertEqual(decoded, original)
    }

    func testStartGameEncodeDecode() throws {
        let config = GameConfig(
            playerCount: 3,
            playerNames: ["A", "B", "C"],
            playerEmojis: ["😀", "🤖", "🎃"],
            aiFlags: [false, true, true]
        )
        let original = GameMessage.startGame(config)
        let data = try original.encoded()
        let decoded = try GameMessage.decoded(from: data)
        XCTAssertEqual(decoded, original)
    }

    func testInvalidDataThrows() {
        let badData = "not json".data(using: .utf8)!
        XCTAssertThrowsError(try GameMessage.decoded(from: badData))
    }
}
