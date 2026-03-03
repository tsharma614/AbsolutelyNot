import SwiftUI

struct GameSetupView: View {
    @StateObject private var viewModel = GameSetupViewModel()
    @State private var navigateToGame = false
    @State private var emojiPickerIndex: Int? = nil

    var body: some View {
        ZStack {
            AppColors.feltGreen.ignoresSafeArea()
            FeltTextureView()
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Title
                    VStack(spacing: 4) {
                        Text("Absolutely Not!")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.goldAccent)

                        Text("A game of reluctant card collecting")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.top, 20)

                    // Player count
                    VStack(spacing: 8) {
                        Text("Players")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)

                        HStack(spacing: 16) {
                            Button {
                                if viewModel.playerCount > 3 {
                                    viewModel.playerCount -= 1
                                }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(viewModel.playerCount > 3 ? AppColors.goldAccent : .gray)
                            }

                            Text("\(viewModel.playerCount)")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(width: 50)

                            Button {
                                if viewModel.playerCount < 7 {
                                    viewModel.playerCount += 1
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(viewModel.playerCount < 7 ? AppColors.goldAccent : .gray)
                            }
                        }

                        Text("\(viewModel.pebblesPerPlayer) pebbles each")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.2))
                    )

                    // Player list
                    VStack(spacing: 12) {
                        ForEach(0..<viewModel.playerCount, id: \.self) { index in
                            PlayerSetupRow(
                                index: index,
                                name: Binding(
                                    get: { viewModel.playerNames[safe: index] ?? "" },
                                    set: { viewModel.playerNames[index] = $0 }
                                ),
                                emoji: Binding(
                                    get: { viewModel.playerEmojis[safe: index] ?? "😀" },
                                    set: { viewModel.playerEmojis[index] = $0 }
                                ),
                                isAI: Binding(
                                    get: { viewModel.isAI[safe: index] ?? true },
                                    set: { viewModel.isAI[index] = $0 }
                                ),
                                onEmojiTap: {
                                    emojiPickerIndex = index
                                }
                            )
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.2))
                    )

                    // Start button
                    Button {
                        navigateToGame = true
                    } label: {
                        Text("Start Game")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.textDark)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(viewModel.isValid ? AppColors.goldAccent : Color.gray)
                            )
                    }
                    .disabled(!viewModel.isValid)
                    .accessibilityIdentifier("startGameButton")
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .navigationDestination(isPresented: $navigateToGame) {
            GamePlayView(config: viewModel.buildConfig())
                .navigationBarBackButtonHidden(true)
        }
        .sheet(item: $emojiPickerIndex) { index in
            EmojiPickerView(selectedEmoji: Binding(
                get: { viewModel.playerEmojis[safe: index] ?? "😀" },
                set: { viewModel.playerEmojis[index] = $0 }
            ))
            .presentationDetents([.medium])
        }
    }
}

extension Int: @retroactive Identifiable {
    public var id: Int { self }
}

struct PlayerSetupRow: View {
    let index: Int
    @Binding var name: String
    @Binding var emoji: String
    @Binding var isAI: Bool
    let onEmojiTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Emoji avatar button
            Button(action: onEmojiTap) {
                Text(emoji)
                    .font(.system(size: 32))
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.2))
                    )
            }

            // Name field
            TextField("Player \(index + 1)", text: $name)
                .textFieldStyle(.plain)
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                )
                .accessibilityIdentifier("playerName\(index)")

            // AI toggle
            Toggle(isOn: $isAI) {
                Text("AI")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
            }
            .toggleStyle(.switch)
            .tint(AppColors.goldAccent)
            .frame(width: 72)
            .accessibilityIdentifier("aiToggle\(index)")
        }
    }
}

#Preview {
    NavigationStack {
        GameSetupView()
    }
}
