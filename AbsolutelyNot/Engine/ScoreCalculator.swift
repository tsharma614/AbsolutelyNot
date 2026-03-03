import Foundation

enum ScoreCalculator {
    /// Calculate score for a player. Lower is better.
    /// Card face values = points. Consecutive runs only count lowest value.
    /// Each pebble = -1 point.
    static func calculateScore(cards: [Card], pebbles: Int) -> Int {
        guard !cards.isEmpty else { return -pebbles }

        let sorted = cards.sorted()
        var totalCardPoints = 0
        var i = 0

        while i < sorted.count {
            let runStart = sorted[i].value
            // Find end of consecutive run
            var j = i
            while j + 1 < sorted.count && sorted[j + 1].value == sorted[j].value + 1 {
                j += 1
            }
            // Only the lowest value in the run counts
            totalCardPoints += runStart
            i = j + 1
        }

        return totalCardPoints - pebbles
    }

    /// Returns a breakdown of the score for display
    static func scoreBreakdown(cards: [Card], pebbles: Int) -> ScoreBreakdown {
        let sorted = cards.sorted()
        var runs: [[Card]] = []
        var totalCardPoints = 0
        var runSavings = 0
        var i = 0

        while i < sorted.count {
            let runStart = sorted[i].value
            var currentRun: [Card] = [sorted[i]]
            var j = i
            while j + 1 < sorted.count && sorted[j + 1].value == sorted[j].value + 1 {
                j += 1
                currentRun.append(sorted[j])
            }
            totalCardPoints += runStart
            if currentRun.count > 1 {
                runs.append(currentRun)
                // Savings = sum of run cards minus the lowest
                let fullSum = currentRun.reduce(0) { $0 + $1.value }
                runSavings += fullSum - runStart
            }
            i = j + 1
        }

        let rawCardTotal = sorted.reduce(0) { $0 + $1.value }

        return ScoreBreakdown(
            rawCardTotal: rawCardTotal,
            runSavings: runSavings,
            pebbleBonus: pebbles,
            finalScore: totalCardPoints - pebbles,
            runs: runs
        )
    }
}

struct ScoreBreakdown: Equatable {
    let rawCardTotal: Int
    let runSavings: Int
    let pebbleBonus: Int
    let finalScore: Int
    let runs: [[Card]]
}
