import SwiftUI

struct PlayerSeatView: View {
    let player: Player
    var isActive: Bool = false
    var isThinking: Bool = false
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 2) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.3))
                    .frame(width: AppLayout.playerSeatSize, height: AppLayout.playerSeatSize)

                if isActive {
                    // Outer glow
                    Circle()
                        .fill(AppColors.goldAccent.opacity(0.25))
                        .frame(width: AppLayout.playerSeatSize + 16, height: AppLayout.playerSeatSize + 16)
                        .blur(radius: 6)
                        .scaleEffect(pulseScale)

                    Circle()
                        .strokeBorder(AppColors.goldAccent, lineWidth: 2.5)
                        .frame(width: AppLayout.playerSeatSize + 4, height: AppLayout.playerSeatSize + 4)
                        .scaleEffect(pulseScale)
                        .onAppear {
                            if isThinking {
                                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                                    pulseScale = 1.15
                                }
                            }
                        }
                        .onChange(of: isThinking) { _, thinking in
                            if thinking {
                                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                                    pulseScale = 1.15
                                }
                            } else {
                                withAnimation(.default) {
                                    pulseScale = 1.0
                                }
                            }
                        }
                }

                Text(player.emoji)
                    .font(.system(size: 22))
            }

            // Name
            Text(player.name)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(1)

            // Stacked run cards
            if !player.collectedCards.isEmpty {
                MiniCardStacksView(cards: player.collectedCards)
            }
        }
    }
}

/// Groups cards into runs and shows each run as a stack (lowest on top)
struct MiniCardStacksView: View {
    let cards: [Card]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(groupedCards.enumerated()), id: \.offset) { _, group in
                MiniRunStack(cards: group)
            }
        }
    }

    private var groupedCards: [[Card]] {
        let sorted = cards.sorted()
        guard !sorted.isEmpty else { return [] }

        var groups: [[Card]] = []
        var currentGroup: [Card] = [sorted[0]]

        for i in 1..<sorted.count {
            if sorted[i].value == sorted[i-1].value + 1 {
                currentGroup.append(sorted[i])
            } else {
                groups.append(currentGroup)
                currentGroup = [sorted[i]]
            }
        }
        groups.append(currentGroup)
        return groups
    }
}

/// A single stack of mini cards — if it's a run, cards overlap with lowest on top.
struct MiniRunStack: View {
    let cards: [Card]

    var body: some View {
        let isRun = cards.count > 1
        // Highest value at the back (bottom), lowest on top (front)
        let reversed = cards.reversed().map { $0 }

        ZStack(alignment: .top) {
            ForEach(Array(reversed.enumerated()), id: \.element.id) { index, card in
                MiniCardView(card: card, isPartOfRun: isRun)
                    .offset(y: CGFloat(index) * AppLayout.miniRunStackOffset)
            }
        }
        .frame(
            width: AppLayout.miniCardWidth,
            height: AppLayout.miniCardHeight + CGFloat(max(0, cards.count - 1)) * AppLayout.miniRunStackOffset
        )
    }
}

#Preview {
    HStack(spacing: 20) {
        PlayerSeatView(
            player: {
                var p = Player(name: "Alice", emoji: "😀", isAI: false, pebbles: 8)
                p.collectedCards = [Card(value: 5), Card(value: 7), Card(value: 8), Card(value: 9), Card(value: 22)]
                return p
            }(),
            isActive: true,
            isThinking: false
        )
        PlayerSeatView(
            player: {
                var p = Player(name: "Bot", emoji: "🤖", isAI: true, pebbles: 10)
                p.collectedCards = [Card(value: 3), Card(value: 4), Card(value: 15)]
                return p
            }(),
            isActive: false,
            isThinking: true
        )
    }
    .padding()
    .background(AppColors.feltGreen)
}
