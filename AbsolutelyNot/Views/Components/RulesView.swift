import SwiftUI

struct RulesView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppColors.feltGreen.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("How to Play")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.goldAccent)
                        Spacer()
                        Button { dismiss() } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }

                    ruleSection("Goal", "Get the **lowest** score. Card values are points. Each pebble subtracts 1 point.")

                    ruleSection("On Your Turn", """
                    **Take** the face-up card (and all pebbles on it), or **Pass** by placing 1 pebble on the card.

                    If you have 0 pebbles, you **must** take the card.
                    """)

                    ruleSection("After Taking", "The next player taps the deck to flip a new card, then decides to take or pass.")

                    ruleSection("Runs", """
                    Consecutive cards (e.g. 7, 8, 9) form a **run**. Only the lowest value counts!

                    Example: 7-8-9 = **7 points** instead of 24.
                    """)

                    ruleSection("Game End", "The game ends when all cards have been taken. Lowest total score wins!")

                    ruleSection("Pebbles", """
                    • 3-5 players: 11 pebbles each
                    • 6 players: 9 pebbles each
                    • 7 players: 7 pebbles each
                    """)

                    ruleSection("Cards", "33 cards (values 3-35). 9 are removed secretly before the game starts — you'll never know which!")
                }
                .padding(20)
                .padding(.bottom, 40)
            }
        }
    }

    private func ruleSection(_ title: String, _ body: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.goldLight)

            Text(body)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.2))
        )
    }
}

#Preview {
    RulesView()
}
