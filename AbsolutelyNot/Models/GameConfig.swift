import Foundation

struct GameConfig: Codable, Equatable {
    let playerCount: Int
    let playerNames: [String]
    let playerEmojis: [String]
    let aiFlags: [Bool]

    static let cardRangeMin = 3
    static let cardRangeMax = 35
    static let totalCards = 33
    static let removedCards = 9
    static let cardsInPlay = 24

    var pebblesPerPlayer: Int {
        switch playerCount {
        case 3...5: return 11
        case 6: return 9
        case 7: return 7
        default: return 11
        }
    }

    var isValid: Bool {
        playerCount >= 3 &&
        playerCount <= 7 &&
        playerNames.count == playerCount &&
        playerEmojis.count == playerCount &&
        aiFlags.count == playerCount &&
        aiFlags.contains(false) // at least 1 human
    }
}
