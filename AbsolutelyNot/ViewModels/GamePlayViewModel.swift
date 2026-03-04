import Foundation
import Combine
import SwiftUI

enum FlavorCategory {
    case pass
    case take
    case forcedTake
}

@MainActor
final class GamePlayViewModel: ObservableObject {
    private(set) var engine: GameEngine
    @Published var showInterstitial = false
    @Published var interstitialPlayerName = ""
    @Published var interstitialPlayerEmoji = ""
    @Published var flavorText: String? = nil
    @Published var showFlavorText = false
    @Published var isFlavorBold = false
    @Published var lastAddedCardId: Int? = nil
    @Published var showCardFlip = false

    private let logger: GameLogger
    private var aiTask: Task<Void, Never>?
    private let isPassAndPlay: Bool
    private var engineCancellable: AnyCancellable?

    // Multiplayer properties
    private var multiplayerService: MultipeerService?
    private(set) var localPlayerID: String?
    private(set) var isMultiplayer = false
    private var isHost = false

    var state: GameState { engine.state }
    var currentCard: Card? { state.currentCard }
    var pebblesOnCard: Int { state.pebblesOnCard }
    var players: [Player] { state.players }
    var currentPlayerIndex: Int { state.currentPlayerIndex }
    var currentPlayer: Player? { state.currentPlayer }
    var drawPileCount: Int { state.drawPile.count }
    var isGameOver: Bool { state.isGameOver }
    var phase: GamePhase { state.phase }

    /// Whether the deck is waiting to be tapped to draw
    var isAwaitingDraw: Bool {
        if case .awaitingDraw = state.phase { return true }
        return false
    }

    /// Whether the human player should tap the deck
    var humanShouldDraw: Bool {
        // Block draw while interstitial is showing (pass-and-play handoff)
        if showInterstitial { return false }
        if case .awaitingDraw(let idx) = state.phase {
            if isMultiplayer {
                return isLocalPlayerIndex(idx)
            }
            return !state.players[idx].isAI
        }
        return false
    }

    // MARK: - Single-device init

    init(config: GameConfig, logger: GameLogger = .shared) {
        self.engine = GameEngine(config: config)
        self.logger = logger
        self.isPassAndPlay = config.aiFlags.filter({ !$0 }).count > 1
        self.engineCancellable = engine.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
        logger.logGameStart(config: config)
        checkForAITurn()
    }

    /// For testing or network sync
    init(engine: GameEngine, logger: GameLogger = .shared, isPassAndPlay: Bool = false) {
        self.engine = engine
        self.logger = logger
        self.isPassAndPlay = isPassAndPlay
        self.engineCancellable = engine.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    // MARK: - Multiplayer init

    init(config: GameConfig, service: MultipeerService, localPlayerID: String, isHost: Bool, logger: GameLogger = .shared) {
        self.engine = GameEngine(config: config)
        self.logger = logger
        self.isPassAndPlay = false
        self.isMultiplayer = true
        self.multiplayerService = service
        self.localPlayerID = localPlayerID
        self.isHost = isHost

        self.engineCancellable = engine.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }

        logger.logGameStart(config: config)
        setupMultiplayerHandlers()

        // Host broadcasts initial state and kicks off AI if needed
        if isHost {
            broadcastState()
            checkForAITurn()
        }
    }

    // MARK: - Multiplayer helpers

    private func setupMultiplayerHandlers() {
        multiplayerService?.onMessageReceived = { [weak self] message in
            Task { @MainActor in
                self?.handleMultiplayerMessage(message)
            }
        }
    }

    private func handleMultiplayerMessage(_ message: GameMessage) {
        switch message {
        case .playerAction(let action, let playerID):
            guard isHost else { return }
            handleRemoteAction(action, from: playerID)
        case .gameState(let newState):
            guard !isHost else { return }
            engine.replaceState(newState)
        default:
            break
        }
    }

    private func handleRemoteAction(_ action: PlayerAction, from playerID: String) {
        guard isHost else { return }
        // Verify it's this player's turn
        let currentName = state.players[state.currentPlayerIndex].name
        guard currentName == playerID else { return }

        switch action {
        case .take:
            engine.takeCard()
        case .pass:
            engine.passCard()
        case .draw:
            engine.drawNextCard()
        }
        broadcastState()

        if !isGameOver {
            checkForAIDraw()
            checkForAITurn()
        }
    }

    private func broadcastState() {
        guard isHost, let service = multiplayerService else { return }
        try? service.send(.gameState(engine.state))
    }

    private func isLocalPlayerIndex(_ index: Int) -> Bool {
        guard let localID = localPlayerID, index < state.players.count else { return false }
        return state.players[index].name == localID
    }

    private var isLocalPlayerTurn: Bool {
        isLocalPlayerIndex(state.currentPlayerIndex)
    }

    // MARK: - Action properties

    var canTake: Bool {
        guard case .playerTurn = state.phase else { return false }
        guard currentCard != nil && !isGameOver else { return false }
        if isMultiplayer {
            return isLocalPlayerTurn
        }
        return isCurrentPlayerHuman
    }

    var canPass: Bool {
        guard case .playerTurn = state.phase else { return false }
        guard let player = currentPlayer else { return false }
        guard player.canPass && !isGameOver else { return false }
        if isMultiplayer {
            return isLocalPlayerTurn
        }
        return isCurrentPlayerHuman
    }

    private var isCurrentPlayerHuman: Bool {
        guard let player = currentPlayer else { return false }
        return !player.isAI
    }

    // MARK: - Actions

    func takeCard() {
        guard canTake else { return }

        if isMultiplayer && !isHost {
            // Client sends action to host
            let playerID = localPlayerID ?? ""
            try? multiplayerService?.send(.playerAction(.take, playerID: playerID))
            return
        }

        let player = state.players[currentPlayerIndex]
        let pebblesBefore = player.pebbles
        let cardPebblesBefore = pebblesOnCard
        let cardValue = currentCard?.value

        let forced = !player.canPass
        let takenCardId = currentCard?.value
        engine.takeCard()

        // Track the card just added to highlight it in hand
        lastAddedCardId = takenCardId

        let pebblesAfter = state.players.first(where: { $0.id == player.id })?.pebbles ?? 0
        logger.logTurn(
            playerName: player.name,
            action: forced ? "FORCED TAKE" : "TAKE",
            cardValue: cardValue,
            pebblesBefore: pebblesBefore,
            pebblesAfter: pebblesAfter,
            cardPebblesBefore: cardPebblesBefore,
            cardPebblesAfter: 0
        )

        HapticManager.impact(.medium)
        showFlavor(forced ? .forcedTake : .take)

        if isMultiplayer && isHost {
            broadcastState()
        }

        if isGameOver {
            let results = engine.rankedResults().map { ($0.player.name, $0.score) }
            logger.logGameEnd(rankedResults: results)
            return
        }

        // Pass-and-play: show interstitial before the next human draws
        if isPassAndPlay, case .awaitingDraw(let drawIdx) = state.phase,
           !state.players[drawIdx].isAI {
            showInterstitialFor(player: state.players[drawIdx])
        }

        checkForAIDraw()
    }

    /// Human taps the deck to draw the next card
    func drawNextCard() {
        guard humanShouldDraw else { return }

        if isMultiplayer && !isHost {
            let playerID = localPlayerID ?? ""
            try? multiplayerService?.send(.playerAction(.draw, playerID: playerID))
            return
        }

        showCardFlip = true
        engine.drawNextCard()
        HapticManager.impact(.light)
        logger.log("\(currentPlayer?.name ?? "?"): DRAW — revealed \(currentCard?.value.description ?? "nil"), remaining: \(drawPileCount)", context: "GameEngine")

        if isMultiplayer && isHost {
            broadcastState()
        }
        handlePostDraw()

        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            showCardFlip = false
        }
    }

    /// AI or automated draw
    private func aiDrawNextCard() {
        let playerName = currentPlayer?.name ?? "AI"
        engine.drawNextCard()
        logger.log("\(playerName): AI DRAW — revealed \(currentCard?.value.description ?? "nil"), remaining: \(drawPileCount)", context: "GameEngine")
        if isMultiplayer && isHost {
            broadcastState()
        }
        handlePostDraw()
    }

    private func handlePostDraw() {
        if isGameOver {
            let results = engine.rankedResults().map { ($0.player.name, $0.score) }
            logger.logGameEnd(rankedResults: results)
            return
        }

        // Pass-and-play: show interstitial if next player is a different human
        if !isMultiplayer && isPassAndPlay, let player = currentPlayer, !player.isAI {
            showInterstitialFor(player: player)
        }

        checkForAITurn()
    }

    func passCard() {
        guard canPass else { return }

        if isMultiplayer && !isHost {
            let playerID = localPlayerID ?? ""
            try? multiplayerService?.send(.playerAction(.pass, playerID: playerID))
            return
        }

        let player = state.players[currentPlayerIndex]
        let pebblesBefore = player.pebbles
        let cardPebblesBefore = pebblesOnCard

        engine.passCard()

        HapticManager.selection()
        logger.logTurn(
            playerName: player.name,
            action: "PASS",
            cardValue: currentCard?.value,
            pebblesBefore: pebblesBefore,
            pebblesAfter: pebblesBefore - 1,
            cardPebblesBefore: cardPebblesBefore,
            cardPebblesAfter: cardPebblesBefore + 1
        )

        showFlavor(.pass)

        if isMultiplayer && isHost {
            broadcastState()
        }

        if isGameOver {
            let results = engine.rankedResults().map { ($0.player.name, $0.score) }
            logger.logGameEnd(rankedResults: results)
            return
        }

        if !isMultiplayer && isPassAndPlay, let player = currentPlayer, !player.isAI {
            showInterstitialFor(player: player)
        }

        checkForAITurn()
    }

    private func showInterstitialFor(player: Player) {
        interstitialPlayerName = player.name
        interstitialPlayerEmoji = player.emoji
        Task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            showInterstitial = true
        }
    }

    func dismissInterstitial() {
        showInterstitial = false
    }

    /// Check if an AI needs to draw after a take
    private func checkForAIDraw() {
        guard case .awaitingDraw(let playerIndex) = state.phase else { return }
        guard state.players[playerIndex].isAI else { return }

        aiTask?.cancel()
        aiTask = Task { [weak self] in
            guard let self = self else { return }
            try? await Task.sleep(nanoseconds: 500_000_000) // short delay for draw
            guard !Task.isCancelled else { return }
            guard case .awaitingDraw(let idx) = self.state.phase, idx == playerIndex else { return }
            self.aiDrawNextCard()
        }
    }

    private func checkForAITurn() {
        guard case .aiThinking(let playerIndex) = state.phase else { return }

        aiTask?.cancel()
        aiTask = Task { [weak self] in
            guard let self = self else { return }

            let delay = UInt64.random(in: 1_000_000_000...2_000_000_000)
            try? await Task.sleep(nanoseconds: delay)

            guard !Task.isCancelled else { return }
            guard self.state.currentPlayerIndex == playerIndex else { return }
            guard let card = self.currentCard else { return }

            let player = self.state.players[playerIndex]
            let shouldTake = AIStrategy.shouldTakeCard(
                card: card,
                pebblesOnCard: self.pebblesOnCard,
                player: player,
                gameState: self.state
            )

            let pebblesBefore = player.pebbles
            let cardPebblesBefore = self.pebblesOnCard

            if shouldTake {
                let forced = !player.canPass
                self.engine.takeCard()

                let pebblesAfter = self.state.players.first(where: { $0.id == player.id })?.pebbles ?? 0
                self.logger.logTurn(
                    playerName: player.name,
                    action: forced ? "FORCED TAKE" : "AI TAKE",
                    cardValue: card.value,
                    pebblesBefore: pebblesBefore,
                    pebblesAfter: pebblesAfter,
                    cardPebblesBefore: cardPebblesBefore,
                    cardPebblesAfter: 0
                )
                self.showFlavor(forced ? .forcedTake : .take)

                if self.isMultiplayer && self.isHost {
                    self.broadcastState()
                }

                if self.isGameOver {
                    let results = self.engine.rankedResults().map { ($0.player.name, $0.score) }
                    self.logger.logGameEnd(rankedResults: results)
                } else {
                    // AI must also draw the next card
                    self.checkForAIDraw()
                }
            } else {
                self.engine.passCard()
                self.logger.logTurn(
                    playerName: player.name,
                    action: "AI PASS",
                    cardValue: card.value,
                    pebblesBefore: pebblesBefore,
                    pebblesAfter: pebblesBefore - 1,
                    cardPebblesBefore: cardPebblesBefore,
                    cardPebblesAfter: cardPebblesBefore + 1
                )
                self.showFlavor(.pass)

                if self.isMultiplayer && self.isHost {
                    self.broadcastState()
                }

                if !self.isGameOver {
                    self.checkForAITurn()
                } else {
                    let results = self.engine.rankedResults().map { ($0.player.name, $0.score) }
                    self.logger.logGameEnd(rankedResults: results)
                }
            }
        }
    }

    private func showFlavor(_ category: FlavorCategory) {
        let text: String
        let bold: Bool

        switch category {
        case .pass:
            text = FlavorText.randomPass()
            bold = text == "ABSOLUTELY NOT."
        case .take:
            text = FlavorText.randomTake()
            bold = false
        case .forcedTake:
            text = FlavorText.randomForcedTake()
            bold = false
        }

        flavorText = text
        isFlavorBold = bold
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            showFlavorText = true
        }

        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            withAnimation(.easeOut(duration: 0.3)) {
                showFlavorText = false
            }
        }
    }

    deinit {
        aiTask?.cancel()
    }
}
