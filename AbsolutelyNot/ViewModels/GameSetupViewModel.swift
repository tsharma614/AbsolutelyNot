import Foundation
import SwiftUI

final class GameSetupViewModel: ObservableObject {
    @Published var playerCount: Int = 3 {
        didSet {
            adjustPlayerArrays()
        }
    }
    @Published var playerNames: [String] = ["Player 1", "Player 2", "Player 3"]
    @Published var playerEmojis: [String] = ["😀", "🤖", "🤖"]
    @Published var isAI: [Bool] = [false, true, true]

    static let defaultEmojis = ["😀", "🤖", "🎃", "🦊", "🐸", "🌵", "🎸"]
    static let defaultNames = ["Player 1", "Player 2", "Player 3", "Player 4", "Player 5", "Player 6", "Player 7"]

    var isValid: Bool {
        playerCount >= 3 &&
        playerCount <= 7 &&
        isAI.contains(false) &&
        playerNames.prefix(playerCount).allSatisfy { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    var pebblesPerPlayer: Int {
        switch playerCount {
        case 3...5: return 11
        case 6: return 9
        case 7: return 7
        default: return 11
        }
    }

    func buildConfig() -> GameConfig {
        GameConfig(
            playerCount: playerCount,
            playerNames: Array(playerNames.prefix(playerCount)),
            playerEmojis: Array(playerEmojis.prefix(playerCount)),
            aiFlags: Array(isAI.prefix(playerCount))
        )
    }

    private func adjustPlayerArrays() {
        while playerNames.count < playerCount {
            let idx = playerNames.count
            playerNames.append(Self.defaultNames[idx])
            playerEmojis.append(Self.defaultEmojis[idx])
            isAI.append(true)
        }
    }
}
