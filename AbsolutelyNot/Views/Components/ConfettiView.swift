import SwiftUI

struct ConfettiPiece: Identifiable {
    let id = UUID()
    let color: Color
    let x: CGFloat
    let delay: Double
    let rotation: Double
    let size: CGFloat
}

struct ConfettiView: View {
    @State private var animate = false

    private let pieces: [ConfettiPiece] = (0..<40).map { i in
        let colors: [Color] = [
            AppColors.goldAccent, AppColors.goldLight,
            .red, .orange, .yellow, .green, .blue, .purple
        ]
        return ConfettiPiece(
            color: colors[i % colors.count],
            x: CGFloat.random(in: 0...1),
            delay: Double.random(in: 0...0.5),
            rotation: Double.random(in: 0...360),
            size: CGFloat.random(in: 4...10)
        )
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(pieces) { piece in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(piece.color)
                        .frame(width: piece.size, height: piece.size * 1.5)
                        .rotationEffect(.degrees(animate ? piece.rotation + 360 : piece.rotation))
                        .position(
                            x: piece.x * geo.size.width,
                            y: animate ? geo.size.height + 50 : -50
                        )
                        .animation(
                            .easeIn(duration: Double.random(in: 1.5...3.0))
                            .delay(piece.delay),
                            value: animate
                        )
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            animate = true
        }
    }
}
