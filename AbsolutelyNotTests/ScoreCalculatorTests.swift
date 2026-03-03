import XCTest
@testable import AbsolutelyNot

final class ScoreCalculatorTests: XCTestCase {

    func testEmptyHand() {
        let score = ScoreCalculator.calculateScore(cards: [], pebbles: 0)
        XCTAssertEqual(score, 0)
    }

    func testEmptyHandWithPebbles() {
        let score = ScoreCalculator.calculateScore(cards: [], pebbles: 5)
        XCTAssertEqual(score, -5)
    }

    func testSingleCard() {
        let score = ScoreCalculator.calculateScore(cards: [Card(value: 15)], pebbles: 0)
        XCTAssertEqual(score, 15)
    }

    func testSingleCardWithPebbles() {
        let score = ScoreCalculator.calculateScore(cards: [Card(value: 15)], pebbles: 3)
        XCTAssertEqual(score, 12)
    }

    func testNonConsecutiveCards() {
        let cards = [Card(value: 5), Card(value: 10), Card(value: 20)]
        let score = ScoreCalculator.calculateScore(cards: cards, pebbles: 0)
        XCTAssertEqual(score, 35) // 5 + 10 + 20
    }

    func testTwoConsecutiveCards() {
        let cards = [Card(value: 10), Card(value: 11)]
        let score = ScoreCalculator.calculateScore(cards: cards, pebbles: 0)
        XCTAssertEqual(score, 10) // Only lowest counts
    }

    func testLongRun() {
        let cards = [Card(value: 27), Card(value: 28), Card(value: 29), Card(value: 30)]
        let score = ScoreCalculator.calculateScore(cards: cards, pebbles: 0)
        XCTAssertEqual(score, 27) // Only 27 counts
    }

    func testMultipleRuns() {
        let cards = [Card(value: 3), Card(value: 4), Card(value: 5), Card(value: 20), Card(value: 21)]
        let score = ScoreCalculator.calculateScore(cards: cards, pebbles: 0)
        XCTAssertEqual(score, 23) // 3 + 20
    }

    func testRunsWithGap() {
        let cards = [Card(value: 10), Card(value: 11), Card(value: 13), Card(value: 14)]
        let score = ScoreCalculator.calculateScore(cards: cards, pebbles: 0)
        XCTAssertEqual(score, 23) // 10 + 13
    }

    func testRunWithPebbles() {
        let cards = [Card(value: 5), Card(value: 6), Card(value: 7)]
        let score = ScoreCalculator.calculateScore(cards: cards, pebbles: 4)
        XCTAssertEqual(score, 1) // 5 - 4
    }

    func testUnsortedInput() {
        let cards = [Card(value: 30), Card(value: 28), Card(value: 29), Card(value: 5)]
        let score = ScoreCalculator.calculateScore(cards: cards, pebbles: 0)
        XCTAssertEqual(score, 33) // 5 + 28
    }

    func testScoreBreakdownRuns() {
        let cards = [Card(value: 10), Card(value: 11), Card(value: 12), Card(value: 25)]
        let breakdown = ScoreCalculator.scoreBreakdown(cards: cards, pebbles: 3)

        XCTAssertEqual(breakdown.rawCardTotal, 58) // 10+11+12+25
        XCTAssertEqual(breakdown.runSavings, 23) // 11+12 = 23 saved
        XCTAssertEqual(breakdown.pebbleBonus, 3)
        XCTAssertEqual(breakdown.finalScore, 32) // 10 + 25 - 3
        XCTAssertEqual(breakdown.runs.count, 1)
        XCTAssertEqual(breakdown.runs[0].count, 3)
    }
}
