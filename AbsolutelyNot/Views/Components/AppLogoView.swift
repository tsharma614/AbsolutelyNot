import SwiftUI

struct AppLogoView: View {
    var scale: CGFloat = 1.0

    private var cardWidth: CGFloat { 100 * scale }
    private var cardHeight: CGFloat { 140 * scale }
    private var pebbleSize: CGFloat { 28 * scale }

    var body: some View {
        ZStack {
            // Red card with gold border
            RoundedRectangle(cornerRadius: 12 * scale)
                .fill(
                    LinearGradient(
                        colors: [AppColors.cardRed, AppColors.cardRedDark],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: cardWidth, height: cardHeight)
                .overlay(
                    RoundedRectangle(cornerRadius: 12 * scale)
                        .strokeBorder(AppColors.goldAccent, lineWidth: 2.5 * scale)
                )
                .shadow(color: .black.opacity(0.4), radius: 6 * scale, x: 2 * scale, y: 3 * scale)

            // "NO!" text
            Text("NO!")
                .font(.system(size: 36 * scale, weight: .black, design: .rounded))
                .foregroundColor(.white)

            // Gold pebble in bottom-right, overlapping card edge
            Circle()
                .fill(
                    RadialGradient(
                        colors: [AppColors.goldLight, AppColors.pebbleGold, AppColors.pebbleGoldDark],
                        center: .init(x: 0.35, y: 0.35),
                        startRadius: 0,
                        endRadius: pebbleSize * 0.6
                    )
                )
                .frame(width: pebbleSize, height: pebbleSize)
                .shadow(color: .black.opacity(0.3), radius: 2 * scale, x: 1 * scale, y: 1 * scale)
                .offset(x: cardWidth * 0.4, y: cardHeight * 0.4)
        }
        .frame(width: cardWidth + pebbleSize * 0.5, height: cardHeight + pebbleSize * 0.5)
    }
}

#Preview {
    ZStack {
        AppColors.feltGreen.ignoresSafeArea()
        VStack(spacing: 30) {
            AppLogoView()
            AppLogoView(scale: 0.5)
            AppLogoView(scale: 0.3)
        }
    }
}
