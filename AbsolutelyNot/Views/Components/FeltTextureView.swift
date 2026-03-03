import SwiftUI

struct FeltTextureView: View {
    var body: some View {
        Canvas { context, size in
            // Draw subtle noise dots for felt texture
            let step: CGFloat = 4
            var x: CGFloat = 0
            while x < size.width {
                var y: CGFloat = 0
                while y < size.height {
                    // Deterministic pseudo-random based on position
                    let hash = Int(x * 31 + y * 17) % 100
                    if hash < 30 {
                        let opacity = Double(hash) / 300.0
                        context.fill(
                            Path(ellipseIn: CGRect(x: x, y: y, width: 1.5, height: 1.5)),
                            with: .color(.white.opacity(opacity))
                        )
                    }
                    y += step
                }
                x += step
            }
        }
        .allowsHitTesting(false)
    }
}
