import Foundation
import MultipeerConnectivity

final class MultipeerService: NSObject, MultiplayerManager, ObservableObject {
    private let serviceType = "absolutelynot"

    private var peerID: MCPeerID!
    private var session: MCSession!
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?

    @Published private(set) var isHost = false
    @Published private(set) var connectionState: ConnectionState = .disconnected
    @Published private(set) var connectedPlayers: [LobbyState.LobbyPlayer] = []

    var onMessageReceived: ((GameMessage) -> Void)?
    var onConnectionStateChanged: ((ConnectionState) -> Void)?

    private var localPlayerName: String = ""
    private var localPlayerEmoji: String = ""

    var localPlayerID: String { peerID?.displayName ?? localPlayerName }

    override init() {
        super.init()
    }

    func hostGame(playerName: String, playerEmoji: String) {
        localPlayerName = playerName
        localPlayerEmoji = playerEmoji
        isHost = true

        peerID = MCPeerID(displayName: playerName)
        session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self

        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: ["emoji": playerEmoji], serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()

        connectionState = .connecting
        onConnectionStateChanged?(.connecting)

        // Add self to lobby
        connectedPlayers = [LobbyState.LobbyPlayer(id: peerID.displayName, name: playerName, emoji: playerEmoji)]
    }

    func joinGame(playerName: String, playerEmoji: String) {
        localPlayerName = playerName
        localPlayerEmoji = playerEmoji
        isHost = false

        peerID = MCPeerID(displayName: playerName)
        session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self

        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()

        connectionState = .connecting
        onConnectionStateChanged?(.connecting)
    }

    func send(_ message: GameMessage) throws {
        let data = try message.encoded()
        try session.send(data, toPeers: session.connectedPeers, with: .reliable)
    }

    func disconnect() {
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        session?.disconnect()
        connectionState = .disconnected
        connectedPlayers = []
        onConnectionStateChanged?(.disconnected)
    }

    private func broadcastLobbyUpdate() {
        guard isHost else { return }
        let update = GameMessage.lobbyUpdate(.waiting(players: connectedPlayers))
        try? send(update)
    }
}

// MARK: - MCSessionDelegate
extension MultipeerService: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            switch state {
            case .connected:
                self.connectionState = .connected
                if self.isHost {
                    // Player was already added from invitation context
                    // If somehow missing (e.g. no context), add with default emoji
                    if !self.connectedPlayers.contains(where: { $0.id == peerID.displayName }) {
                        let player = LobbyState.LobbyPlayer(id: peerID.displayName, name: peerID.displayName, emoji: "🎮")
                        self.connectedPlayers.append(player)
                    }
                    self.broadcastLobbyUpdate()
                }
                self.onConnectionStateChanged?(.connected)
            case .notConnected:
                if self.isHost {
                    self.connectedPlayers.removeAll { $0.id == peerID.displayName }
                    self.broadcastLobbyUpdate()
                }
                if session.connectedPeers.isEmpty {
                    self.connectionState = .disconnected
                    self.onConnectionStateChanged?(.disconnected)
                }
            case .connecting:
                self.connectionState = .connecting
                self.onConnectionStateChanged?(.connecting)
            @unknown default:
                break
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard let message = try? GameMessage.decoded(from: data) else { return }
        DispatchQueue.main.async { [weak self] in
            self?.onMessageReceived?(message)
        }
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension MultipeerService: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // Auto-accept connections (up to 7 players)
        let totalPlayers = session.connectedPeers.count + 1 // +1 for self
        if totalPlayers < 7 {
            // Extract name + emoji from context
            if let context = context,
               let info = try? JSONDecoder().decode([String: String].self, from: context),
               let name = info["name"],
               let emoji = info["emoji"] {
                DispatchQueue.main.async { [weak self] in
                    let player = LobbyState.LobbyPlayer(id: peerID.displayName, name: name, emoji: emoji)
                    if !(self?.connectedPlayers.contains(where: { $0.id == player.id }) ?? true) {
                        self?.connectedPlayers.append(player)
                    }
                }
            }
            invitationHandler(true, session)
        } else {
            invitationHandler(false, nil)
        }
    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.connectionState = .error(error.localizedDescription)
            self?.onConnectionStateChanged?(.error(error.localizedDescription))
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension MultipeerService: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        // Encode name + emoji as context data in the invite
        let contextInfo = ["name": localPlayerName, "emoji": localPlayerEmoji]
        let contextData = try? JSONEncoder().encode(contextInfo)
        browser.invitePeer(peerID, to: session, withContext: contextData, timeout: 30)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}

    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.connectionState = .error(error.localizedDescription)
            self?.onConnectionStateChanged?(.error(error.localizedDescription))
        }
    }
}
