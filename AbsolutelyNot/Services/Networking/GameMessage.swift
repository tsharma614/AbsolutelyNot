import Foundation

enum PlayerAction: Codable, Equatable {
    case take
    case pass
    case draw
}

enum LobbyState: Codable, Equatable {
    case waiting(players: [LobbyPlayer])
    case starting

    struct LobbyPlayer: Codable, Equatable, Identifiable {
        let id: String
        let name: String
        let emoji: String
    }
}

enum GameMessage: Codable, Equatable {
    case gameState(GameState)
    case playerAction(PlayerAction, playerID: String)
    case lobbyUpdate(LobbyState)
    case startGame(GameConfig)

    func encoded() throws -> Data {
        try JSONEncoder().encode(self)
    }

    static func decoded(from data: Data) throws -> GameMessage {
        try JSONDecoder().decode(GameMessage.self, from: data)
    }
}
