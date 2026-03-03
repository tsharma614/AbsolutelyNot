import Foundation

enum AIStrategy {
    /// Decides whether the AI should take the current card.
    /// Stateless pure function — all inputs provided as parameters.
    static func shouldTakeCard(
        card: Card,
        pebblesOnCard: Int,
        player: Player,
        gameState: GameState
    ) -> Bool {
        // Forced: 0 pebbles → must take
        if !player.canPass {
            return true
        }

        // Profitable: pebbles on card >= card value
        if pebblesOnCard >= card.value {
            return true
        }

        // Run extension: card is ±1 of a card in hand → take if effective cost is low
        let handValues = Set(player.collectedCards.map { $0.value })
        let extendsRun = handValues.contains(card.value - 1) || handValues.contains(card.value + 1)

        if extendsRun {
            // Effective cost = card value - savings from run - pebbles gained
            // If extending a run, the card effectively costs just 1 point (it won't count)
            // plus we gain the pebbles. So take if pebbles >= 1 or card value is low.
            let effectiveCost = max(0, 1 - pebblesOnCard)
            if effectiveCost <= 2 {
                return true
            }
        }

        // Cheap card: value ≤ 10 and decent pebbles on it
        if card.value <= 10 && pebblesOnCard >= 2 {
            return true
        }

        // Cheap card without pebbles: very low value
        if card.value <= 5 {
            return true
        }

        // Threshold: pebbles >= 60% of card value
        if Double(pebblesOnCard) >= Double(card.value) * 0.6 {
            return true
        }

        // Default: pass
        return false
    }
}
