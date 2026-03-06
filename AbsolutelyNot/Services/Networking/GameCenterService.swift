import Foundation
import GameKit

final class GameCenterService: NSObject, MultiplayerManager {
    private var match: GKMatch?
    private var localPlayer: GKLocalPlayer { GKLocalPlayer.local }

    private(set) var isHost = false
    private(set) var connectionState: ConnectionState = .disconnected
    private(set) var connectedPlayers: [LobbyState.LobbyPlayer] = []

    var onMessageReceived: ((GameMessage) -> Void)?
    var onConnectionStateChanged: ((ConnectionState) -> Void)?

    private var localPlayerName: String = ""
    private var localPlayerEmoji: String = ""

    override init() {
        super.init()
    }

    /// Authenticate the local player with Game Center
    static func authenticate(completion: @escaping (Bool) -> Void) {
        GKLocalPlayer.local.authenticateHandler = { viewController, error in
            if let _ = viewController {
                // Present the Game Center sign-in view controller
                // The hosting view should handle presenting this
                completion(false)
            } else if error != nil {
                completion(false)
            } else {
                completion(GKLocalPlayer.local.isAuthenticated)
            }
        }
    }

    func hostGame(playerName: String, playerEmoji: String) {
        localPlayerName = playerName
        localPlayerEmoji = playerEmoji
        isHost = true
        findMatch()
    }

    func joinGame(playerName: String, playerEmoji: String) {
        localPlayerName = playerName
        localPlayerEmoji = playerEmoji
        isHost = false
        findMatch()
    }

    private func findMatch() {
        let request = GKMatchRequest()
        request.minPlayers = 3
        request.maxPlayers = 7

        connectionState = .connecting
        onConnectionStateChanged?(.connecting)

        GKMatchmaker.shared().findMatch(for: request) { [weak self] match, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let error = error {
                    self.connectionState = .error(error.localizedDescription)
                    self.onConnectionStateChanged?(.error(error.localizedDescription))
                    return
                }

                guard let match = match else { return }
                self.match = match
                match.delegate = self
                self.connectionState = .connected
                self.onConnectionStateChanged?(.connected)

                // Determine host: player with lowest gamePlayerID
                self.determineHost()
            }
        }
    }

    private func determineHost() {
        guard let match = match else { return }
        var allPlayerIDs = match.players.map { $0.gamePlayerID }
        allPlayerIDs.append(localPlayer.gamePlayerID)
        allPlayerIDs.sort()

        isHost = allPlayerIDs.first == localPlayer.gamePlayerID

        connectedPlayers = match.players.map { player in
            LobbyState.LobbyPlayer(id: player.gamePlayerID, name: player.displayName, emoji: "🎮")
        }
        // Add self
        connectedPlayers.insert(
            LobbyState.LobbyPlayer(id: localPlayer.gamePlayerID, name: localPlayerName, emoji: localPlayerEmoji),
            at: 0
        )
    }

    func send(_ message: GameMessage) throws {
        guard let match = match else { return }
        let data = try message.encoded()
        try match.sendData(toAllPlayers: data, with: .reliable)
    }

    func markGameActive() {
        // Game Center handles reconnection internally
    }

    func sendGracefulDisconnect() {
        disconnect()
    }

    func disconnect() {
        match?.disconnect()
        match = nil
        connectionState = .disconnected
        connectedPlayers = []
        onConnectionStateChanged?(.disconnected)
    }
}

// MARK: - GKMatchDelegate
extension GameCenterService: GKMatchDelegate {
    func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
        guard let message = try? GameMessage.decoded(from: data) else { return }
        DispatchQueue.main.async { [weak self] in
            self?.onMessageReceived?(message)
        }
    }

    func match(_ match: GKMatch, player: GKPlayer, didChange state: GKPlayerConnectionState) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            switch state {
            case .connected:
                self.determineHost()
                self.onConnectionStateChanged?(.connected)
            case .disconnected:
                self.connectedPlayers.removeAll { $0.id == player.gamePlayerID }
                if match.players.isEmpty {
                    self.connectionState = .disconnected
                    self.onConnectionStateChanged?(.disconnected)
                }
            default:
                break
            }
        }
    }

    func match(_ match: GKMatch, didFailWithError error: Error?) {
        DispatchQueue.main.async { [weak self] in
            self?.connectionState = .error(error?.localizedDescription ?? "Unknown error")
            self?.onConnectionStateChanged?(.error(error?.localizedDescription ?? "Unknown error"))
        }
    }
}
