import SwiftUI

enum LobbyMode {
    case wifi
    case gameCenter
}

struct LobbyView: View {
    let mode: LobbyMode
    @StateObject private var service = MultipeerService()
    @State private var isHosting = false
    @State private var hasJoined = false
    @State private var playerName = ""
    @State private var playerEmoji = "😀"
    @State private var navigateToGame = false
    @State private var gameConfig: GameConfig?
    @State private var showEmojiPicker = false
    @State private var clientLobbyPlayers: [LobbyState.LobbyPlayer] = []
    @State private var cpuCount = 0

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

                // Name & emoji input (shown before hosting/joining)
                if !isHosting && !hasJoined {
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Button {
                                showEmojiPicker = true
                            } label: {
                                Text(playerEmoji)
                                    .font(.system(size: 32))
                                    .frame(width: 48, height: 48)
                                    .background(
                                        Circle()
                                            .fill(Color.black.opacity(0.2))
                                    )
                            }

                            TextField("Your Name", text: $playerName)
                                .textFieldStyle(.plain)
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .medium))
                                .padding(.horizontal, 12)
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
                }

                // Player list
                VStack(spacing: 8) {
                    Text("Players (\(displayedPlayers.count))")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    ForEach(displayedPlayers) { player in
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

                // CPU players control (host only)
                if isHosting {
                    HStack(spacing: 16) {
                        Text("CPU Players")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)

                        Spacer()

                        Button {
                            if cpuCount > 0 { cpuCount -= 1 }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                                .foregroundColor(cpuCount > 0 ? AppColors.goldAccent : .gray)
                        }
                        .disabled(cpuCount == 0)

                        Text("\(cpuCount)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(width: 30)

                        Button {
                            let maxCPU = 7 - service.connectedPlayers.count
                            if cpuCount < maxCPU { cpuCount += 1 }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(totalPlayerCount < 7 ? AppColors.goldAccent : .gray)
                        }
                        .disabled(totalPlayerCount >= 7)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.2))
                    )
                }

                Spacer()

                // Action buttons
                if !isHosting && !hasJoined {
                    VStack(spacing: 12) {
                        Button("Host Game") {
                            startHosting()
                        }
                        .buttonStyle(GoldButtonStyle())
                        .disabled(effectiveName.isEmpty)

                        Button("Join Game") {
                            startJoining()
                        }
                        .buttonStyle(GoldButtonStyle())
                        .disabled(effectiveName.isEmpty)
                    }
                }

                if isHosting && totalPlayerCount >= 3 {
                    Button("Start Game") {
                        startMultiplayerGame()
                    }
                    .buttonStyle(GoldButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
        .onAppear {
            if playerName.isEmpty {
                playerName = "Player"
            }
        }
        .sheet(isPresented: $showEmojiPicker) {
            EmojiPickerView(selectedEmoji: $playerEmoji)
                .presentationDetents([.medium])
        }
        .navigationDestination(isPresented: $navigateToGame) {
            if let config = gameConfig {
                GamePlayView(config: config, service: service, localPlayerID: service.localPlayerID, isHost: service.isHost)
                    .navigationBarBackButtonHidden(true)
            }
        }
    }

    private var displayedPlayers: [LobbyState.LobbyPlayer] {
        isHosting ? service.connectedPlayers : clientLobbyPlayers
    }

    private var totalPlayerCount: Int {
        displayedPlayers.count + cpuCount
    }

    private var effectiveName: String {
        playerName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var statusColor: Color {
        switch service.connectionState {
        case .connected: return .green
        case .connecting: return .yellow
        case .disconnected: return .gray
        case .error: return .red
        }
    }

    private var statusText: String {
        switch service.connectionState {
        case .connected: return "Connected"
        case .connecting: return isHosting ? "Waiting for players..." : "Looking for games..."
        case .disconnected: return "Not connected"
        case .error(let msg): return "Error: \(msg)"
        }
    }

    private func startHosting() {
        isHosting = true
        service.onMessageReceived = { message in
            handleMessage(message)
        }
        service.hostGame(playerName: effectiveName, playerEmoji: playerEmoji)
    }

    private func startJoining() {
        hasJoined = true
        service.onMessageReceived = { message in
            handleMessage(message)
        }
        service.joinGame(playerName: effectiveName, playerEmoji: playerEmoji)
    }

    private func handleMessage(_ message: GameMessage) {
        switch message {
        case .lobbyUpdate(let state):
            if case .waiting(let players) = state {
                clientLobbyPlayers = players
            }
        case .startGame(let config):
            // Client receives start signal
            gameConfig = config
            navigateToGame = true
        default:
            break
        }
    }

    private static let cpuPool: [(name: String, emoji: String)] = [
        ("Jonathan", "🤖"), ("Nikhil", "🧠"), ("Trusha", "👾"),
        ("Som", "🎰"), ("Meha", "🦾"), ("Ishan", "🕹️"),
        ("Vikram", "🎲"), ("Amit", "🃏"), ("Tejal", "🎯"),
        ("Akshay", "🏆"), ("Tanmay", "🧩"), ("Ambi", "🎮"),
    ]

    private func startMultiplayerGame() {
        var names = service.connectedPlayers.map { $0.name }
        var emojis = service.connectedPlayers.map { $0.emoji }
        var aiFlags = Array(repeating: false, count: service.connectedPlayers.count)

        // Pick random CPU names from the pool, avoiding duplicates with real players
        var availableCPUs = Self.cpuPool.filter { cpu in !names.contains(cpu.name) }.shuffled()
        for _ in 0..<cpuCount {
            guard let cpu = availableCPUs.popLast() else { break }
            names.append(cpu.name)
            emojis.append(cpu.emoji)
            aiFlags.append(true)
        }

        let config = GameConfig(
            playerCount: names.count,
            playerNames: names,
            playerEmojis: emojis,
            aiFlags: aiFlags
        )
        gameConfig = config
        try? service.send(.startGame(config))
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
