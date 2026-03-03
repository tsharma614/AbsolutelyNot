import SwiftUI

struct PebbleView: View {
    var size: CGFloat = AppLayout.pebbleSize

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [AppColors.goldLight, AppColors.pebbleGold, AppColors.pebbleGoldDark],
                    center: .init(x: 0.35, y: 0.35),
                    startRadius: 0,
                    endRadius: size * 0.6
                )
            )
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .strokeBorder(AppColors.pebbleGoldDark, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 1, x: 0.5, y: 0.5)
    }
}

#Preview {
    HStack {
        PebbleView()
        PebbleView(size: 30)
    }
    .padding()
    .background(AppColors.feltGreen)
}
