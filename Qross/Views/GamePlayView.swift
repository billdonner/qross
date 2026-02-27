import SwiftUI

struct GamePlayView: View {
    @Bindable var game: GameState
    let onExit: () -> Void

    private var topicColors: [String: Color] {
        let colored = TopicPalette.assign(to: game.selectedTopics)
        return Dictionary(uniqueKeysWithValues: colored.map { ($0.id, $0.color) })
    }

    private var gameOver: Bool {
        game.phase == .won || game.phase == .lostWrong || game.phase == .lostStuck
    }

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            if game.board != nil {
                // Board always visible once game starts
                BoardView(game: game, topicColors: topicColors)

                // Result overlay when game ends
                if gameOver {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .transition(.opacity)

                    resultOverlay
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            } else {
                ProgressView()
            }
        }
        .animation(.spring(duration: 0.4), value: gameOver)
    }

    private var resultOverlay: some View {
        let won = game.phase == .won
        let reason: String? = switch game.phase {
        case .lostWrong: "Too many wrong answers!"
        case .lostStuck: "No moves left!"
        default: nil
        }

        return VStack(spacing: 16) {
            // Result header
            HStack(spacing: 12) {
                Text(won ? "🎉" : "💥")
                    .font(.system(size: 40))
                Text(won ? "You Won!" : "Game Over")
                    .font(.title.bold())
            }

            if let reason {
                Text(reason)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Score card
            HStack(spacing: 24) {
                VStack {
                    Text("\(game.moveCount)")
                        .font(.title2.bold())
                    Text("moves")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                VStack {
                    Text("\(game.wrongCount)")
                        .font(.title2.bold())
                    Text("wrong")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                VStack {
                    Text("\(game.score)")
                        .font(.title2.bold())
                        .foregroundStyle(won ? .green : .red)
                    Text("score")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if won {
                Text("Best possible: \(game.minPossibleScore)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Actions
            HStack(spacing: 16) {
                if won {
                    let shareText = game.shareText()
                    ShareLink(item: shareText) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .font(.callout.bold())
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                    }
                }

                Button {
                    onExit()
                } label: {
                    Text("Done")
                        .font(.callout.bold())
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(won ? Color.green : Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(24)
        .background(.ultraThickMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 20)
        .padding(.horizontal, 24)
    }
}
