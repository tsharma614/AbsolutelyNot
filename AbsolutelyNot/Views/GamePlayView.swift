import SwiftUI

struct GamePlayView: View {
    @StateObject private var viewModel: GamePlayViewModel
    @State private var navigateToGameOver = false
    @State private var showRules = false
    @State private var cardFlipRotation: Double = 0

    init(config: GameConfig) {
        _viewModel = StateObject(wrappedValue: GamePlayViewModel(config: config))
    }

    /// The human player index (always shown at bottom)
    private var humanPlayerIndex: Int {
        viewModel.players.firstIndex(where: { !$0.isAI }) ?? 0
    }

    /// Opponents = everyone except the human at the bottom
    private var opponents: [(index: Int, player: Player)] {
        viewModel.players.enumerated()
            .filter { $0.offset != humanPlayerIndex }
            .map { (index: $0.offset, player: $0.element) }
    }

    private var humanPlayer: Player {
        viewModel.players[safe: humanPlayerIndex] ?? viewModel.players[0]
    }

    var body: some View {
        ZStack {
            AppColors.feltGreen.ignoresSafeArea()
            FeltTextureView()
                .ignoresSafeArea()

            GeometryReader { geo in
                let tableHeight = geo.size.height - bottomBarHeight

                // Opponent seats
                ForEach(Array(opponents.enumerated()), id: \.element.index) { seatIndex, opponent in
                    PlayerSeatView(
                        player: opponent.player,
                        isActive: viewModel.currentPlayerIndex == opponent.index,
                        isThinking: isAIThinking(playerIndex: opponent.index)
                    )
                    .position(seatPosition(seatIndex: seatIndex, totalOpponents: opponents.count, size: CGSize(width: geo.size.width, height: tableHeight)))
                }

                // Center: Card + Pebbles + Deck
                HStack(spacing: 16) {
                    // Current card with pebbles (or empty slot when awaiting draw)
                    if let card = viewModel.currentCard {
                        ZStack {
                            CardView(card: card)
                                .rotation3DEffect(
                                    .degrees(cardFlipRotation),
                                    axis: (x: 0, y: 1, z: 0)
                                )
                            PebblePileOnCardView(count: viewModel.pebblesOnCard)
                        }
                    } else if viewModel.isAwaitingDraw {
                        // Empty card slot
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(AppColors.goldAccent.opacity(0.2), style: StrokeStyle(lineWidth: 2, dash: [6]))
                            .frame(width: AppLayout.cardWidth, height: AppLayout.cardHeight)
                    }

                    // Deck — tappable when awaiting draw
                    Button {
                        if viewModel.humanShouldDraw {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                viewModel.drawNextCard()
                            }
                        }
                    } label: {
                        DeckView(
                            remaining: viewModel.drawPileCount,
                            highlightTappable: viewModel.humanShouldDraw
                        )
                    }
                    .disabled(!viewModel.humanShouldDraw)
                    .accessibilityIdentifier("deckButton")
                }
                .position(x: geo.size.width / 2, y: tableHeight * 0.45)

                // Turn indicator banner
                turnBanner
                    .position(x: geo.size.width / 2, y: 28)

                // Rules button
                Button { showRules = true } label: {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.5))
                }
                .position(x: geo.size.width - 30, y: 28)

                // Flavor text popup
                if viewModel.showFlavorText, let text = viewModel.flavorText {
                    Text(text)
                        .font(.system(
                            size: viewModel.isFlavorBold ? 18 : 14,
                            weight: viewModel.isFlavorBold ? .black : .semibold,
                            design: .rounded
                        ))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.7))
                        )
                        .transition(.scale.combined(with: .opacity))
                        .position(x: geo.size.width / 2, y: tableHeight * 0.6)
                }
            }

            // Bottom: Human player hand + controls
            VStack(spacing: 0) {
                Spacer()
                bottomBar
            }
        }
        .fullScreenCover(isPresented: $viewModel.showInterstitial) {
            InterstitialView(
                playerName: viewModel.interstitialPlayerName,
                playerEmoji: viewModel.interstitialPlayerEmoji
            ) {
                viewModel.dismissInterstitial()
            }
        }
        .navigationDestination(isPresented: $navigateToGameOver) {
            GameOverView(engine: viewModel.engine)
                .navigationBarBackButtonHidden(true)
        }
        .onChange(of: viewModel.isGameOver) { _, isOver in
            if isOver {
                HapticManager.notification(.success)
                Task {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    navigateToGameOver = true
                }
            }
        }
        .onChange(of: viewModel.showCardFlip) { _, flipping in
            if flipping {
                cardFlipRotation = -90
                withAnimation(.easeOut(duration: AppAnimation.cardFlipDuration)) {
                    cardFlipRotation = 0
                }
            }
        }
        .sheet(isPresented: $showRules) {
            RulesView()
        }
    }

    private var turnBanner: some View {
        Group {
            if viewModel.isGameOver {
                EmptyView()
            } else if viewModel.humanShouldDraw {
                Text("Tap deck to draw")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.goldAccent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.black.opacity(0.5)))
            } else if let player = viewModel.currentPlayer {
                let isHuman = !player.isAI
                Text(isHuman ? "Your turn" : "\(player.name) is thinking...")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(isHuman ? AppColors.goldAccent : .white.opacity(0.7))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.black.opacity(0.5)))
            }
        }
    }

    private var bottomBarHeight: CGFloat { 190 }

    private var bottomBar: some View {
        VStack(spacing: 6) {
            // Player info bar
            HStack {
                Text(humanPlayer.emoji)
                    .font(.system(size: 20))
                Text(humanPlayer.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()

                // Draw prompt
                if viewModel.humanShouldDraw {
                    Text("Tap deck to draw")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.goldAccent)
                        .transition(.opacity)
                }

                HStack(spacing: 3) {
                    PebbleView(size: 12)
                    Text("\(humanPlayer.pebbles)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.goldAccent)
                }
            }
            .padding(.horizontal, 14)

            // Cards + Action buttons
            HStack(alignment: .bottom, spacing: 8) {
                PlayerHandView(cards: humanPlayer.collectedCards, highlightCardId: viewModel.lastAddedCardId)
                    .frame(maxWidth: .infinity)

                // Action buttons
                VStack(spacing: 6) {
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            viewModel.takeCard()
                        }
                    } label: {
                        Text("Take")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(width: 70, height: 36)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(viewModel.canTake ? AppColors.cardRed : Color.gray.opacity(0.5))
                            )
                    }
                    .disabled(!viewModel.canTake)
                    .accessibilityIdentifier("takeButton")

                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            viewModel.passCard()
                        }
                    } label: {
                        Text("Pass")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.textDark)
                            .frame(width: 70, height: 36)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(viewModel.canPass ? AppColors.goldAccent : Color.gray.opacity(0.5))
                            )
                    }
                    .disabled(!viewModel.canPass)
                    .accessibilityIdentifier("passButton")
                }
                .padding(.trailing, 10)
            }
        }
        .padding(.vertical, 10)
        .frame(height: bottomBarHeight)
        .background(
            Rectangle()
                .fill(Color.black.opacity(0.3))
        )
    }

    private func isAIThinking(playerIndex: Int) -> Bool {
        if case .aiThinking(let idx) = viewModel.phase {
            return idx == playerIndex
        }
        return false
    }

    /// Position opponent seats in an oval around the top and sides
    private func seatPosition(seatIndex: Int, totalOpponents: Int, size: CGSize) -> CGPoint {
        let centerX = size.width / 2
        let topMargin: CGFloat = 50
        let sideMargin: CGFloat = 40

        guard totalOpponents > 0 else { return CGPoint(x: centerX, y: topMargin) }

        let angle: CGFloat
        if totalOpponents == 1 {
            angle = .pi
        } else if totalOpponents == 2 {
            let angles: [CGFloat] = [.pi * 0.75, .pi * 0.25]
            angle = angles[seatIndex]
        } else {
            let startAngle: CGFloat = .pi * 0.88
            let endAngle: CGFloat = .pi * 0.12
            let step = (startAngle - endAngle) / CGFloat(totalOpponents - 1)
            angle = startAngle - step * CGFloat(seatIndex)
        }

        let radiusX = (size.width / 2) - sideMargin
        let radiusY = (size.height * 0.38) - topMargin

        let x = centerX + radiusX * cos(angle)
        let y = size.height * 0.35 - radiusY * sin(angle)

        return CGPoint(x: x, y: max(topMargin, y))
    }
}

struct InterstitialView: View {
    let playerName: String
    let playerEmoji: String
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.9).ignoresSafeArea()

            VStack(spacing: 20) {
                Text(playerEmoji)
                    .font(.system(size: 80))

                Text("Pass to \(playerName)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("Tap anywhere to continue")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .onTapGesture {
            onDismiss()
        }
    }
}

#if DEBUG
#Preview {
    GamePlayView(config: PreviewData.sampleConfig)
}
#endif
