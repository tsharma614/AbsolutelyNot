import SwiftUI

struct CardView: View {
    let card: Card
    var isFaceUp: Bool = true
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: isFaceUp ? [AppColors.cardRed, AppColors.cardRedDark] : [AppColors.deckBlue, AppColors.deckBlue.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.3), radius: 4, x: 2, y: 2)

            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(AppColors.goldAccent, lineWidth: 2)

            RoundedRectangle(cornerRadius: 11)
                .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                .padding(2)

            if isFaceUp {
                Text("\(card.value)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            } else {
                Text("?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .frame(width: AppLayout.cardWidth, height: AppLayout.cardHeight)
        .rotation3DEffect(
            .degrees(rotation),
            axis: (x: 0, y: 1, z: 0)
        )
    }

    func flipIn() -> CardView {
        var view = self
        view._rotation = State(initialValue: 0)
        return view
    }
}

#Preview {
    HStack(spacing: 20) {
        CardView(card: Card(value: 26))
        CardView(card: Card(value: 7), isFaceUp: false)
    }
    .padding()
    .background(AppColors.feltGreen)
}
