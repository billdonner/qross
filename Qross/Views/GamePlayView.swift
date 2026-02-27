import SwiftUI

struct GamePlayView: View {
    @Bindable var game: GameState
    let onExit: () -> Void

    private var topicColors: [String: Color] {
        let colored = TopicPalette.assign(to: game.selectedTopics)
        return Dictionary(uniqueKeysWithValues: colored.map { ($0.id, $0.color) })
    }

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            switch game.phase {
            case .playing:
                BoardView(game: game, topicColors: topicColors)

            case .won:
                resultView(won: true)

            case .lostWrong:
                resultView(won: false, reason: "Too many wrong answers!")

            case .lostStuck:
                resultView(won: false, reason: "No moves left!")

            default:
                ProgressView()
            }
        }
    }

    private func resultView(won: Bool, reason: String? = nil) -> some View {
        VStack(spacing: 24) {
            Spacer()

            // Result emoji
            Text(won ? "🎉" : "💥")
                .font(.system(size: 80))

            Text(won ? "You Won!" : "Game Over")
                .font(.largeTitle.bold())

            if let reason {
                Text(reason)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            // Score card
            VStack(spacing: 12) {
                HStack {
                    Label("\(game.moveCount)", systemImage: "arrow.right.circle")
                    Spacer()
                    Text("moves")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Label("\(game.wrongCount)", systemImage: "xmark.circle")
                    Spacer()
                    Text("wrong")
                        .foregroundStyle(.secondary)
                }
                Divider()
                HStack {
                    Text("Score")
                        .font(.headline)
                    Spacer()
                    Text("\(game.score)")
                        .font(.title2.bold())
                }
                if won {
                    Text("Min possible: \(game.minPossibleScore)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(20)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 40)

            // Share card
            if won {
                let shareText = game.shareText()
                ShareLink(item: shareText) {
                    Label("Share Result", systemImage: "square.and.arrow.up")
                        .font(.callout.bold())
                }
            }

            Spacer()

            // Actions
            VStack(spacing: 12) {
                Button {
                    onExit()
                } label: {
                    Text("Back to Home")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 32)
        }
    }
}
