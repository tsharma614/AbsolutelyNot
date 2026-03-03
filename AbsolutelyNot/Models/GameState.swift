import Foundation

enum GamePhase: Equatable, Codable {
    case setup
    case playerTurn(playerIndex: Int)
    case aiThinking(playerIndex: Int)
    case awaitingDraw(playerIndex: Int)  // after taking, must tap deck to flip next card
    case gameOver
}

struct GameState: Codable, Equatable {
    var players: [Player]
    var drawPile: [Card]
    var currentCard: Card?
    var pebblesOnCard: Int
    var currentPlayerIndex: Int
    var removedCards: [Card]
    var phase: GamePhase

    var isGameOver: Bool {
        phase == .gameOver
    }

    var currentPlayer: Player? {
        guard currentPlayerIndex >= 0, currentPlayerIndex < players.count else { return nil }
        return players[currentPlayerIndex]
    }

    var cardsRemaining: Int {
        drawPile.count
    }

    static var empty: GameState {
        GameState(
            players: [],
            drawPile: [],
            currentCard: nil,
            pebblesOnCard: 0,
            currentPlayerIndex: 0,
            removedCards: [],
            phase: .setup
        )
    }
}
