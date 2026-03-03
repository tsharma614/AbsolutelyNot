import Foundation
import Combine

final class GameEngine: ObservableObject {
    @Published private(set) var state: GameState

    init(config: GameConfig) {
        var deck = Card.fullDeck().shuffled()

        // Remove 9 cards face-down
        let removed = Array(deck.prefix(GameConfig.removedCards))
        deck.removeFirst(GameConfig.removedCards)

        // Flip the first card
        let firstCard = deck.removeFirst()

        // Create players
        let players = (0..<config.playerCount).map { i in
            Player(
                name: config.playerNames[i],
                emoji: config.playerEmojis[i],
                isAI: config.aiFlags[i],
                pebbles: config.pebblesPerPlayer
            )
        }

        self.state = GameState(
            players: players,
            drawPile: deck,
            currentCard: firstCard,
            pebblesOnCard: 0,
            currentPlayerIndex: 0,
            removedCards: removed,
            phase: .playerTurn(playerIndex: 0)
        )
    }

    /// Initialize with a pre-built state (for testing or network sync)
    init(state: GameState) {
        self.state = state
    }

    /// Current player takes the face-up card and all pebbles on it.
    /// Turn advances to the next player, who must draw the next card.
    func takeCard() {
        guard let card = state.currentCard, !state.isGameOver else { return }

        let idx = state.currentPlayerIndex
        state.players[idx].addCard(card, withPebbles: state.pebblesOnCard)
        state.pebblesOnCard = 0
        state.currentCard = nil

        // If draw pile is empty, game over
        if state.drawPile.isEmpty {
            state.phase = .gameOver
        } else {
            // Advance to next player — they must draw from the deck
            state.currentPlayerIndex = (idx + 1) % state.players.count
            state.phase = .awaitingDraw(playerIndex: state.currentPlayerIndex)
        }
    }

    /// Draw the next card from the deck. The drawing player then decides to take or pass.
    func drawNextCard() {
        guard case .awaitingDraw = state.phase else { return }
        guard !state.drawPile.isEmpty else {
            state.phase = .gameOver
            return
        }

        state.currentCard = state.drawPile.removeFirst()

        // The player who drew now decides on this card
        updatePhaseForCurrentPlayer()
    }

    /// Current player passes by placing a pebble on the card.
    /// Turn advances to next player.
    func passCard() {
        guard !state.isGameOver else { return }
        let idx = state.currentPlayerIndex
        guard state.players[idx].canPass else { return }

        state.players[idx].spendPebble()
        state.pebblesOnCard += 1

        // Advance to next player
        state.currentPlayerIndex = (idx + 1) % state.players.count
        updatePhaseForCurrentPlayer()
    }

    /// Update phase based on current player type
    private func updatePhaseForCurrentPlayer() {
        let idx = state.currentPlayerIndex
        if state.players[idx].isAI {
            state.phase = .aiThinking(playerIndex: idx)
        } else {
            state.phase = .playerTurn(playerIndex: idx)
        }
    }

    /// Get ranked results (lowest score first = winner)
    func rankedResults() -> [(player: Player, score: Int, breakdown: ScoreBreakdown)] {
        state.players.map { player in
            let breakdown = ScoreCalculator.scoreBreakdown(cards: player.collectedCards, pebbles: player.pebbles)
            return (player: player, score: breakdown.finalScore, breakdown: breakdown)
        }
        .sorted { $0.score < $1.score }
    }
}
