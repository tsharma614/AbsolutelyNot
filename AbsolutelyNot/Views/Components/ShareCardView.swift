import SwiftUI

struct ShareCardView: View {
    let results: [PlayerResult]

    private var winner: PlayerResult? { results.first }

    var body: some View {
        VStack(spacing: 16) {
            // Logo
            AppLogoView(scale: 0.35)
                .padding(.top, 16)

            // Winner
            if let winner = winner {
                VStack(spacing: 4) {
                    Text(winner.emoji)
                        .font(.system(size: 48))

                    Text("\(winner.name) wins!")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.goldAccent)

                    Text("Score: \(winner.score)")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }
            }

            // Gold divider
            Rectangle()
                .fill(AppColors.goldAccent)
                .frame(height: 1)
                .padding(.horizontal, 20)

            // All results
            VStack(spacing: 8) {
                ForEach(results) { result in
                    HStack {
                        Text("#\(result.rank)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(result.isWinner ? AppColors.goldAccent : .white.opacity(0.7))
                            .frame(width: 28, alignment: .leading)

                        Text(result.emoji)
                            .font(.system(size: 18))

                        Text(result.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(result.isWinner ? AppColors.goldAccent : .white)

                        Spacer()

                        Text("\(result.score)")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(result.isWinner ? AppColors.goldAccent : .white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(result.isWinner ? AppColors.goldAccent.opacity(0.12) : Color.clear)
                    )
                    .padding(.horizontal, 12)
                }
            }

            // Footer branding
            Text("Absolutely Not!")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.4))
                .padding(.bottom, 16)
        }
        .frame(width: 360)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.feltGreen)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(AppColors.goldAccent, lineWidth: 2)
                )
        )
    }
}
