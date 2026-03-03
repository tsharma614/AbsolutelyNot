import SwiftUI

struct EmojiPickerView: View {
    @Binding var selectedEmoji: String
    @Environment(\.dismiss) private var dismiss

    private let emojis = [
        "😀", "😎", "🥳", "🤩", "😈", "👻", "🤖", "👽",
        "🎃", "🦊", "🐸", "🐱", "🐶", "🦁", "🐻", "🐼",
        "🌵", "🎸", "🎯", "🎲", "🔥", "⭐", "🌈", "💎",
        "🍕", "🍩", "🎪", "🚀", "🏆", "👑", "🦄", "🐙",
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                    ForEach(emojis, id: \.self) { emoji in
                        Button {
                            selectedEmoji = emoji
                            dismiss()
                        } label: {
                            Text(emoji)
                                .font(.system(size: 44))
                                .frame(width: 64, height: 64)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedEmoji == emoji ? AppColors.goldAccent.opacity(0.3) : Color.clear)
                                )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Avatar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    EmojiPickerView(selectedEmoji: .constant("😀"))
}
