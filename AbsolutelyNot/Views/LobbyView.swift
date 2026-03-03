import SwiftUI

enum LobbyMode {
    case wifi
    case gameCenter
}

struct LobbyView: View {
    let mode: LobbyMode
    @State private var isHosting = false
    @State private var playerName = "Player"
    @State private var playerEmoji = "😀"
    @State private var service: (any MultiplayerManager)?
    @State private var lobbyPlayers: [LobbyState.LobbyPlayer] = []
    @State private var connectionState: ConnectionState = .disconnected
    @State private var navigateToGame = false

    var body: some View {
        ZStack {
            AppColors.feltGreen.ignoresSafeArea()

            VStack(spacing: 24) {
                Text(mode == .wifi ? "WiFi Game" : "Online Game")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.goldAccent)

                // Connection status
                HStack(spacing: 8) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 10, height: 10)
                    Text(statusText)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }

                // Player list
                VStack(spacing: 8) {
                    Text("Players (\(lobbyPlayers.count))")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    ForEach(lobbyPlayers) { player in
                        HStack {
                            Text(player.emoji)
                                .font(.system(size: 24))
                            Text(player.name)
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.1))
                        )
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.2))
                )

                Spacer()

                // Action buttons
                if !isHosting && service == nil {
                    VStack(spacing: 12) {
                        Button("Host Game") {
                            startHosting()
                        }
                        .buttonStyle(GoldButtonStyle())

                        Button("Join Game") {
                            startJoining()
                        }
                        .buttonStyle(GoldButtonStyle())
                    }
                }

                if isHosting && lobbyPlayers.count >= 3 {
                    Button("Start Game") {
                        startMultiplayerGame()
                    }
                    .buttonStyle(GoldButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
    }

    private var statusColor: Color {
        switch connectionState {
        case .connected: return .green
        case .connecting: return .yellow
        case .disconnected: return .gray
        case .error: return .red
        }
    }

    private var statusText: String {
        switch connectionState {
        case .connected: return "Connected"
        case .connecting: return isHosting ? "Waiting for players..." : "Looking for games..."
        case .disconnected: return "Not connected"
        case .error(let msg): return "Error: \(msg)"
        }
    }

    private func startHosting() {
        isHosting = true
        let svc: any MultiplayerManager = mode == .wifi ? MultipeerService() : GameCenterService()
        service = svc
        svc.onMessageReceived = { message in
            if case .lobbyUpdate(let state) = message,
               case .waiting(let players) = state {
                lobbyPlayers = players
            }
        }
        svc.onConnectionStateChanged = { state in
            connectionState = state
        }
        svc.hostGame(playerName: playerName, playerEmoji: playerEmoji)
        lobbyPlayers = svc.connectedPlayers
    }

    private func startJoining() {
        let svc: any MultiplayerManager = mode == .wifi ? MultipeerService() : GameCenterService()
        service = svc
        svc.onMessageReceived = { message in
            if case .lobbyUpdate(let state) = message,
               case .waiting(let players) = state {
                lobbyPlayers = players
            }
        }
        svc.onConnectionStateChanged = { state in
            connectionState = state
        }
        svc.joinGame(playerName: playerName, playerEmoji: playerEmoji)
    }

    private func startMultiplayerGame() {
        // Host creates config from lobby players and starts game
        let config = GameConfig(
            playerCount: lobbyPlayers.count,
            playerNames: lobbyPlayers.map { $0.name },
            playerEmojis: lobbyPlayers.map { $0.emoji },
            aiFlags: Array(repeating: false, count: lobbyPlayers.count)
        )
        try? service?.send(.startGame(config))
        navigateToGame = true
    }
}

struct GoldButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundColor(AppColors.textDark)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(configuration.isPressed ? AppColors.pebbleGoldDark : AppColors.goldAccent)
            )
    }
}

#Preview {
    NavigationStack {
        LobbyView(mode: .wifi)
    }
}
