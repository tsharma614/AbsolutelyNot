import SwiftUI

struct GameOverView: View {
    @StateObject private var viewModel: GameOverViewModel
    @State private var navigateToSetup = false

    init(engine: GameEngine) {
        _viewModel = StateObject(wrappedValue: GameOverViewModel(engine: engine))
    }

    @State private var showConfetti = false
    @State private var rowsAppeared = false

    var body: some View {
        ZStack {
            AppColors.feltGreen.ignoresSafeArea()
            FeltTextureView()
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Logo + Winner announcement
                    AppLogoView(scale: 0.4)
                        .padding(.top, 16)

                    if let winner = viewModel.winner {
                        VStack(spacing: 8) {
                            Text(winner.emoji)
                                .font(.system(size: 64))

                            Text("\(winner.name) wins!")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(AppColors.goldAccent)

                            Text("Score: \(winner.score)")
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }

                    // All results
                    VStack(spacing: 12) {
                        ForEach(Array(viewModel.results.enumerated()), id: \.element.id) { index, result in
                            ResultRow(result: result)
                                .offset(x: rowsAppeared ? 0 : 60)
                                .opacity(rowsAppeared ? 1.0 : 0.0)
                                .animation(
                                    .spring(response: 0.5, dampingFraction: 0.75)
                                        .delay(Double(index) * 0.1),
                                    value: rowsAppeared
                                )
                        }
                    }
                    .padding(.horizontal, 20)

                    // Action buttons
                    VStack(spacing: 12) {
                        Button {
                            navigateToSetup = true
                        } label: {
                            Text("New Game")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(AppColors.textDark)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(AppColors.goldAccent)
                                )
                        }
                        .accessibilityIdentifier("newGameButton")
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }

            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            showConfetti = true
            HapticManager.notification(.success)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                rowsAppeared = true
            }
        }
        .navigationDestination(isPresented: $navigateToSetup) {
            GameSetupView()
                .navigationBarBackButtonHidden(true)
        }
    }
}

struct ResultRow: View {
    let result: PlayerResult

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                // Rank + avatar
                HStack(spacing: 8) {
                    Text("#\(result.rank)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(result.isWinner ? AppColors.goldAccent : .white.opacity(0.7))
                        .frame(width: 30)

                    Text(result.emoji)
                        .font(.system(size: 28))

                    Text(result.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }

                Spacer()

                // Score
                Text("\(result.score)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(result.isWinner ? AppColors.goldAccent : .white)
            }

            // Breakdown
            HStack(spacing: 16) {
                BreakdownItem(label: "Cards", value: "\(result.breakdown.rawCardTotal)")
                BreakdownItem(label: "Run savings", value: "-\(result.breakdown.runSavings)")
                BreakdownItem(label: "Pebbles", value: "-\(result.breakdown.pebbleBonus)")
            }
            .padding(.leading, 38)

            // Runs info
            if !result.breakdown.runs.isEmpty {
                HStack(spacing: 4) {
                    Text("Runs:")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))

                    ForEach(result.breakdown.runs, id: \.self) { run in
                        Text(run.map { "\($0.value)" }.joined(separator: "-"))
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(AppColors.goldAccent.opacity(0.8))
                    }
                }
                .padding(.leading, 38)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    result.isWinner
                        ? LinearGradient(colors: [AppColors.goldAccent.opacity(0.15), AppColors.pebbleGoldDark.opacity(0.08)], startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(colors: [Color.black.opacity(0.2), Color.black.opacity(0.2)], startPoint: .leading, endPoint: .trailing)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(result.isWinner ? AppColors.goldAccent.opacity(0.5) : Color.clear, lineWidth: 1)
        )
    }
}

struct BreakdownItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.4))
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        GameOverView(engine: PreviewData.sampleEngine)
    }
}
#endif
