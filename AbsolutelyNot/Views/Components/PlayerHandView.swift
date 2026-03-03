import SwiftUI

struct PlayerHandView: View {
    let cards: [Card]
    var highlightCardId: Int? = nil

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(groupedCards.enumerated()), id: \.offset) { _, group in
                        HandRunStack(cards: group, highlightCardId: highlightCardId)
                    }
                }
                .padding(.horizontal, 12)
            }
            .fixedSize(horizontal: false, vertical: true)
            .onChange(of: highlightCardId) { _, newValue in
                if let newValue {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(newValue, anchor: .center)
                    }
                }
            }
        }
    }

    /// Group cards into consecutive runs
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

/// A stack of hand-sized cards — runs overlap with lowest value on top
struct HandRunStack: View {
    let cards: [Card]
    var highlightCardId: Int? = nil

    var body: some View {
        let isRun = cards.count > 1
        // Highest value at the back (bottom), lowest on top (front)
        let reversed = cards.reversed().map { $0 }

        ZStack(alignment: .top) {
            ForEach(Array(reversed.enumerated()), id: \.element.id) { index, card in
                HandCardView(card: card, isPartOfRun: isRun, isHighlighted: card.value == highlightCardId)
                    .id(card.value)
                    .offset(y: CGFloat(index) * AppLayout.runStackOffset)
            }
        }
        .frame(
            width: AppLayout.handCardWidth,
            height: AppLayout.handCardHeight + CGFloat(max(0, cards.count - 1)) * AppLayout.runStackOffset
        )
    }
}

struct HandCardView: View {
    let card: Card
    var isPartOfRun: Bool = false
    var isHighlighted: Bool = false
    @State private var glowOpacity: Double = 0

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [AppColors.cardRed, AppColors.cardRedDark],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)

            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(isPartOfRun ? AppColors.goldAccent : AppColors.goldAccent.opacity(0.4), lineWidth: isPartOfRun ? 2 : 1)

            Text("\(card.value)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .frame(width: AppLayout.handCardWidth, height: AppLayout.handCardHeight)
        .shadow(color: AppColors.goldAccent.opacity(glowOpacity), radius: 8)
        .onAppear {
            if isHighlighted {
                withAnimation(.easeOut(duration: 0.4)) { glowOpacity = 0.8 }
                Task {
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    withAnimation(.easeOut(duration: 0.5)) { glowOpacity = 0 }
                }
            }
        }
        .onChange(of: isHighlighted) { _, highlighted in
            if highlighted {
                withAnimation(.easeOut(duration: 0.4)) { glowOpacity = 0.8 }
                Task {
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    withAnimation(.easeOut(duration: 0.5)) { glowOpacity = 0 }
                }
            }
        }
    }
}

#Preview {
    PlayerHandView(cards: [
        Card(value: 5), Card(value: 7), Card(value: 8), Card(value: 9),
        Card(value: 13), Card(value: 26), Card(value: 27), Card(value: 28), Card(value: 30)
    ])
    .padding()
    .background(AppColors.feltGreen)
}
