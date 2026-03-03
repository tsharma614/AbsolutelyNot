import SwiftUI

struct DeckView: View {
    let remaining: Int
    var highlightTappable: Bool = false

    var body: some View {
        ZStack {
            // Stack effect — offset cards behind
            ForEach(0..<min(remaining, 3), id: \.self) { i in
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppColors.deckBlue.opacity(1.0 - Double(i) * 0.15))
                    .frame(width: AppLayout.deckWidth, height: AppLayout.deckHeight)
                    .offset(x: CGFloat(i) * 1.5, y: CGFloat(-i) * 1.5)
            }

            // Top card
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [AppColors.deckBlue, AppColors.deckBlue.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        highlightTappable ? AppColors.goldAccent : AppColors.goldAccent.opacity(0.4),
                        lineWidth: highlightTappable ? 2.5 : 1
                    )

                VStack(spacing: 2) {
                    if highlightTappable {
                        Text("Draw")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.goldAccent)
                    } else {
                        Text("?")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.4))
                    }

                    Text("\(remaining)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .frame(width: AppLayout.deckWidth, height: AppLayout.deckHeight)
        }
        .shadow(color: highlightTappable ? AppColors.goldAccent.opacity(0.4) : .clear, radius: 8)
    }
}

#Preview {
    HStack(spacing: 30) {
        DeckView(remaining: 20)
        DeckView(remaining: 3, highlightTappable: true)
    }
    .padding()
    .background(AppColors.feltGreen)
}
