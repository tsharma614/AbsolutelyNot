import Foundation

struct PlayerResult: Identifiable {
    let id: UUID
    let rank: Int
    let name: String
    let emoji: String
    let score: Int
    let breakdown: ScoreBreakdown
    let isWinner: Bool
}

@MainActor
final class GameOverViewModel: ObservableObject {
    @Published private(set) var results: [PlayerResult] = []

    init(engine: GameEngine) {
        let ranked = engine.rankedResults()
        let winnerScore = ranked.first?.score ?? 0

        self.results = ranked.enumerated().map { index, entry in
            PlayerResult(
                id: entry.player.id,
                rank: index + 1,
                name: entry.player.name,
                emoji: entry.player.emoji,
                score: entry.score,
                breakdown: entry.breakdown,
                isWinner: entry.score == winnerScore && index == 0
            )
        }
    }

    var winner: PlayerResult? {
        results.first
    }
}
