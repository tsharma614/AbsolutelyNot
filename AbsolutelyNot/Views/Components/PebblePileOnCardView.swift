import SwiftUI

struct PebblePileOnCardView: View {
    let count: Int

    var body: some View {
        ZStack {
            // Pebbles scattered on the card
            ForEach(0..<count, id: \.self) { index in
                PebbleView(size: pebbleSize)
                    .offset(pebbleOffset(for: index))
            }
        }
        .frame(width: AppLayout.cardWidth, height: AppLayout.cardHeight)
        .overlay(alignment: .topTrailing) {
            if count > 0 {
                // Count badge — prominent pebble counter
                HStack(spacing: 3) {
                    PebbleView(size: 10)
                    Text("\(count)")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(AppColors.goldAccent)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.85))
                        .shadow(color: AppColors.goldAccent.opacity(0.4), radius: 4)
                )
                .offset(x: 16, y: -12)
            }
        }
    }

    private var pebbleSize: CGFloat {
        count > 10 ? 14 : AppLayout.pebbleSize
    }

    /// Deterministic scatter positions seeded by index
    private func pebbleOffset(for index: Int) -> CGSize {
        let maxSpread: CGFloat = count <= 3 ? 25 : (count <= 7 ? 35 : 40)

        // Use a simple seeded pseudo-random based on index
        let seed1 = Double(((index + 1) * 7 + 13) % 37) / 37.0
        let seed2 = Double(((index + 1) * 11 + 23) % 41) / 41.0

        let x = (seed1 - 0.5) * 2 * maxSpread
        let y = (seed2 - 0.5) * 2 * maxSpread

        return CGSize(width: x, height: y)
    }
}

#Preview {
    VStack(spacing: 30) {
        ZStack {
            CardView(card: Card(value: 26))
            PebblePileOnCardView(count: 3)
        }
        ZStack {
            CardView(card: Card(value: 15))
            PebblePileOnCardView(count: 10)
        }
    }
    .padding()
    .background(AppColors.feltGreen)
}
