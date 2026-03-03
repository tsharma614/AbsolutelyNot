import Foundation

enum PreviewData {
    static let sampleConfig = GameConfig(
        playerCount: 4,
        playerNames: ["Alice", "Bot Bob", "Bot Carol", "Bot Dave"],
        playerEmojis: ["😀", "🤖", "🎃", "🦊"],
        aiFlags: [false, true, true, true]
    )

    static var sampleEngine: GameEngine {
        GameEngine(config: sampleConfig)
    }

    static var sampleGameState: GameState {
        var state = GameState(
            players: [
                Player(name: "Alice", emoji: "😀", isAI: false, pebbles: 8),
                Player(name: "Bot Bob", emoji: "🤖", isAI: true, pebbles: 10),
                Player(name: "Bot Carol", emoji: "🎃", isAI: true, pebbles: 11),
                Player(name: "Bot Dave", emoji: "🦊", isAI: true, pebbles: 9),
            ],
            drawPile: (10...25).map { Card(value: $0) },
            currentCard: Card(value: 26),
            pebblesOnCard: 3,
            currentPlayerIndex: 0,
            removedCards: [],
            phase: .playerTurn(playerIndex: 0)
        )
        state.players[0].collectedCards = [Card(value: 5), Card(value: 7), Card(value: 27), Card(value: 30)]
        state.players[1].collectedCards = [Card(value: 8), Card(value: 9)]
        state.players[2].collectedCards = [Card(value: 15)]
        return state
    }

    static var samplePlayers: [Player] {
        sampleGameState.players
    }
}
