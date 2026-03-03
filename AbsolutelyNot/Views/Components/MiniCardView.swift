import SwiftUI

struct MiniCardView: View {
    let card: Card
    var isPartOfRun: Bool = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(isPartOfRun ? AppColors.goldAccent.opacity(0.3) : AppColors.cardRed)
                .shadow(color: .black.opacity(0.2), radius: 0.5, x: 0.5, y: 0.5)

            RoundedRectangle(cornerRadius: 3)
                .strokeBorder(isPartOfRun ? AppColors.goldAccent : AppColors.goldAccent.opacity(0.5), lineWidth: 0.5)

            Text("\(card.value)")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .frame(width: AppLayout.miniCardWidth, height: AppLayout.miniCardHeight)
    }
}

#Preview {
    HStack(spacing: 4) {
        MiniCardView(card: Card(value: 7))
        MiniCardView(card: Card(value: 8), isPartOfRun: true)
        MiniCardView(card: Card(value: 9), isPartOfRun: true)
        MiniCardView(card: Card(value: 22))
    }
    .padding()
    .background(AppColors.feltGreen)
}
