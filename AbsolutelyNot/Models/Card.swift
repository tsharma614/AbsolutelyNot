import Foundation

struct Card: Identifiable, Hashable, Comparable, Codable {
    let value: Int

    var id: Int { value }

    static func < (lhs: Card, rhs: Card) -> Bool {
        lhs.value < rhs.value
    }

    /// Creates the full deck of cards (3-35)
    static func fullDeck() -> [Card] {
        (3...35).map { Card(value: $0) }
    }
}
