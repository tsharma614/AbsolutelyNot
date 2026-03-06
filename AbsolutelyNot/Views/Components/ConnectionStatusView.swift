import SwiftUI

struct ConnectionLostOverlay: View {
    let playerName: String

    @State private var countdown = 15

    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 48))
                    .foregroundColor(.yellow)

                Text("\(playerName) disconnected")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                HStack(spacing: 12) {
                    ProgressView()
                        .tint(.white)
                    Text("Reconnecting...")
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }

                Text("\(countdown)s remaining")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(AppColors.goldAccent)
            }
        }
        .onAppear {
            startCountdown()
        }
    }

    private func startCountdown() {
        Task {
            while countdown > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if countdown > 0 { countdown -= 1 }
            }
        }
    }
}

struct HostDisconnectedOverlay: View {
    let onReturnToMenu: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.red)

                Text("Host disconnected")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("The game can no longer continue.")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))

                Button(action: onReturnToMenu) {
                    Text("Return to Menu")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textDark)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(AppColors.goldAccent)
                        )
                }
                .padding(.top, 8)
            }
        }
    }
}
