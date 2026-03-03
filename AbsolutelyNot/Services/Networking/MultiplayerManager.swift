import Foundation
import Combine

enum ConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case error(String)
}

protocol MultiplayerManager: AnyObject {
    var isHost: Bool { get }
    var connectionState: ConnectionState { get }
    var connectedPlayers: [LobbyState.LobbyPlayer] { get }
    var onMessageReceived: ((GameMessage) -> Void)? { get set }
    var onConnectionStateChanged: ((ConnectionState) -> Void)? { get set }

    func hostGame(playerName: String, playerEmoji: String)
    func joinGame(playerName: String, playerEmoji: String)
    func send(_ message: GameMessage) throws
    func disconnect()
}
