import Foundation

struct Player: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var emoji: String
    var isAI: Bool
    var pebbles: Int
    var collectedCards: [Card]  // kept sorted

    var canPass: Bool {
        pebbles > 0
    }

    var cardCount: Int {
        collectedCards.count
    }

    init(id: UUID = UUID(), name: String, emoji: String, isAI: Bool, pebbles: Int) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.isAI = isAI
        self.pebbles = pebbles
        self.collectedCards = []
    }

    mutating func addCard(_ card: Card, withPebbles pebbles: Int) {
        collectedCards.append(card)
        collectedCards.sort()
        self.pebbles += pebbles
    }

    mutating func spendPebble() {
        guard canPass else { return }
        pebbles -= 1
    }
}
