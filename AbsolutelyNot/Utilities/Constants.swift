import SwiftUI

enum AppColors {
    static let feltGreen = Color(red: 0.1, green: 0.35, blue: 0.15)
    static let feltGreenLight = Color(red: 0.15, green: 0.45, blue: 0.2)
    static let cardRed = Color(red: 0.7, green: 0.1, blue: 0.15)
    static let cardRedDark = Color(red: 0.5, green: 0.08, blue: 0.1)
    static let goldAccent = Color(red: 0.85, green: 0.7, blue: 0.3)
    static let goldLight = Color(red: 0.95, green: 0.85, blue: 0.5)
    static let pebbleGold = Color(red: 0.9, green: 0.75, blue: 0.35)
    static let pebbleGoldDark = Color(red: 0.7, green: 0.55, blue: 0.2)
    static let deckBlue = Color(red: 0.15, green: 0.2, blue: 0.5)
    static let textLight = Color.white
    static let textDark = Color(red: 0.15, green: 0.1, blue: 0.05)
}

enum AppLayout {
    static let cardWidth: CGFloat = 80
    static let cardHeight: CGFloat = 112
    static let miniCardWidth: CGFloat = 22
    static let miniCardHeight: CGFloat = 30
    static let pebbleSize: CGFloat = 16
    static let playerSeatSize: CGFloat = 40
    static let handCardWidth: CGFloat = 50
    static let handCardHeight: CGFloat = 70
    static let deckWidth: CGFloat = 60
    static let deckHeight: CGFloat = 84
    /// How much each stacked run card peeks out (vertical offset)
    static let runStackOffset: CGFloat = 14
    static let miniRunStackOffset: CGFloat = 8
}

enum AppAnimation {
    static let cardFlipDuration: Double = 0.4
    static let pebbleSlideDuration: Double = 0.3
    static let takeCardDuration: Double = 0.5
    static let flavorTextIn: Double = 0.4
    static let flavorTextHold: Double = 1.5
    static let flavorTextOut: Double = 0.3
    static let cardDealDelay: Double = 0.2
    static let runHighlightDuration: Double = 2.0
}
