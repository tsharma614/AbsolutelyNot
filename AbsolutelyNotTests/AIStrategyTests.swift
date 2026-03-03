import XCTest
@testable import AbsolutelyNot

final class AIStrategyTests: XCTestCase {

    private func makeState(currentCard: Int = 20, pebblesOnCard: Int = 0, playerPebbles: Int = 11, playerCards: [Int] = []) -> (Card, Player, GameState) {
        let card = Card(value: currentCard)
        var player = Player(name: "AI", emoji: "🤖", isAI: true, pebbles: playerPebbles)
        player.collectedCards = playerCards.map { Card(value: $0) }.sorted()

        let state = GameState(
            players: [player],
            drawPile: [],
            currentCard: card,
            pebblesOnCard: pebblesOnCard,
            currentPlayerIndex: 0,
            removedCards: [],
            phase: .aiThinking(playerIndex: 0)
        )
        return (card, player, state)
    }

    func testForcedTakeZeroPebbles() {
        let (card, player, state) = makeState(currentCard: 35, pebblesOnCard: 0, playerPebbles: 0)
        XCTAssertTrue(AIStrategy.shouldTakeCard(card: card, pebblesOnCard: 0, player: player, gameState: state))
    }

    func testProfitableTake() {
        let (card, player, state) = makeState(currentCard: 10, pebblesOnCard: 12, playerPebbles: 11)
        XCTAssertTrue(AIStrategy.shouldTakeCard(card: card, pebblesOnCard: 12, player: player, gameState: state))
    }

    func testRunExtensionTake() {
        let (card, player, state) = makeState(currentCard: 11, pebblesOnCard: 0, playerPebbles: 11, playerCards: [10])
        XCTAssertTrue(AIStrategy.shouldTakeCard(card: card, pebblesOnCard: 0, player: player, gameState: state))
    }

    func testCheapCardWithPebbles() {
        let (card, player, state) = makeState(currentCard: 8, pebblesOnCard: 3, playerPebbles: 11)
        XCTAssertTrue(AIStrategy.shouldTakeCard(card: card, pebblesOnCard: 3, player: player, gameState: state))
    }

    func testVeryLowValueCard() {
        let (card, player, state) = makeState(currentCard: 4, pebblesOnCard: 0, playerPebbles: 11)
        XCTAssertTrue(AIStrategy.shouldTakeCard(card: card, pebblesOnCard: 0, player: player, gameState: state))
    }

    func testThresholdTake() {
        // 60% of 30 = 18
        let (card, player, state) = makeState(currentCard: 30, pebblesOnCard: 18, playerPebbles: 11)
        XCTAssertTrue(AIStrategy.shouldTakeCard(card: card, pebblesOnCard: 18, player: player, gameState: state))
    }

    func testDefaultPass() {
        let (card, player, state) = makeState(currentCard: 30, pebblesOnCard: 2, playerPebbles: 11)
        XCTAssertFalse(AIStrategy.shouldTakeCard(card: card, pebblesOnCard: 2, player: player, gameState: state))
    }

    func testHighValueNoIncentivePass() {
        let (card, player, state) = makeState(currentCard: 35, pebblesOnCard: 5, playerPebbles: 11)
        XCTAssertFalse(AIStrategy.shouldTakeCard(card: card, pebblesOnCard: 5, player: player, gameState: state))
    }
}
