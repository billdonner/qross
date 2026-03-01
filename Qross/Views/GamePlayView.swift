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
                // Board always visible once game starts — dimmed when game over
                BoardView(game: game, topicColors: topicColors, onQuit: gameOver ? nil : onExit)
                    .opacity(gameOver ? 0.3 : 1.0)
                    .allowsHitTesting(!gameOver)

                // Result overlay when game ends — compact, pinned to top
                if gameOver {
                    VStack {
                        resultOverlay
                            .padding(.top, 60)
                        Spacer()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
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

        return VStack(spacing: 10) {
            // Top row: result title + score stats
            HStack {
                // Left: title + reason
                HStack(spacing: 8) {
                    Text(won ? "🎉" : "💥")
                        .font(.system(size: 28))
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(won ? "You Won!" : "Game Over")
                                .font(.title3.bold())
                            if game.mode == .doubleCross {
                                Text("Double Cross")
                                    .font(.caption.bold())
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 1)
                                    .background(Color.purple.opacity(0.2))
                                    .foregroundStyle(.purple)
                                    .clipShape(Capsule())
                            }
                        }
                        if let reason {
                            Text(reason)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                // Right: score
                VStack(spacing: 2) {
                    Text("\(game.score)")
                        .font(.title2.bold())
                        .foregroundStyle(won ? .green : .red)
                    Text("score")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Stats row
            HStack(spacing: 0) {
                statItem(value: "\(game.moveCount)", label: "moves")
                Spacer()
                statItem(value: "\(game.wrongCount)", label: "wrong")
                if game.hintPenalty > 0 {
                    Spacer()
                    statItem(value: "+\(game.hintPenalty)", label: "hints", color: .orange)
                }
                if won {
                    Spacer()
                    statItem(value: "\(game.minPossibleScore)", label: "best", color: .secondary)
                }
            }

            // Actions
            HStack(spacing: 12) {
                if won {
                    let shareText = game.shareText()
                    ShareLink(item: shareText) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .font(.callout.bold())
                            .frame(maxWidth: .infinity)
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
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(won ? Color.green : Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(.ultraThickMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 20)
        .padding(.horizontal, 12)
    }

    private func statItem(value: String, label: String, color: Color = .primary) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.callout.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
