import SwiftUI

struct GamePlayView: View {
    @Bindable var game: GameState
    let onExit: () -> Void

    @State private var topicColors: [String: Color] = [:]
    @State private var postGameAnalysis: String?
    @State private var isAnalyzing = false
    @State private var showConfetti = false

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
                    ScrollView {
                        resultOverlay
                            .padding(.top, 60)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Confetti on win
                if showConfetti {
                    ConfettiView()
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }
            } else {
                ProgressView()
            }
        }
        .animation(.spring(duration: 0.4), value: gameOver)
        .onAppear {
            let colored = TopicPalette.assign(to: game.selectedTopics)
            topicColors = Dictionary(uniqueKeysWithValues: colored.map { ($0.id, $0.color) })
        }
        .onChange(of: game.phase) { _, newPhase in
            if newPhase == .won {
                HapticEngine.win()
                showConfetti = true
                fetchAnalysis()
            } else if newPhase == .lostWrong || newPhase == .lostStuck {
                HapticEngine.lose()
                fetchAnalysis()
            }
        }
    }

    private var resultOverlay: some View {
        let won = game.phase == .won
        let topicResults = computeTopicResults()

        return VStack(spacing: 10) {
            // Top row: result title
            HStack {
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
                        if !won {
                            Text(loseMessage(topicResults: topicResults))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(3)
                        }
                    }
                }
                Spacer()
            }

            // Score breakdown formula
            scoreBreakdown(won: won)

            // Topic performance bars
            if !topicResults.isEmpty {
                topicPerformanceBars(topicResults: topicResults)
            }

            // AI Analysis
            if let analysis = postGameAnalysis {
                Text(analysis)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity)
            } else if isAnalyzing {
                HStack(spacing: 6) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Analyzing...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .transition(.opacity)
            }

            // Actions
            HStack(spacing: 12) {
                let shareText = game.shareText()
                ShareLink(item: shareText) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.callout.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
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

    // MARK: - Score Breakdown

    private func scoreBreakdown(won: Bool) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text("Moves")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(game.moveCount)")
                    .font(.callout.bold().monospacedDigit())
            }
            HStack {
                Text("Wrong")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(game.wrongCount) x2 = \(game.wrongCount * 2)")
                    .font(.callout.bold().monospacedDigit())
                    .foregroundStyle(game.wrongCount > 0 ? .red : .primary)
            }
            if game.hintPenalty > 0 {
                HStack {
                    Text("Hints")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(game.hintPenalty)")
                        .font(.callout.bold().monospacedDigit())
                        .foregroundStyle(.orange)
                }
            }
            Divider()
            HStack {
                Text("Score")
                    .font(.callout.bold())
                Spacer()
                HStack(spacing: 8) {
                    Text("\(game.score)")
                        .font(.title3.bold().monospacedDigit())
                        .foregroundStyle(won ? .green : .red)
                    if won {
                        Text("(best: \(game.minPossibleScore))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Lose Message

    private func loseMessage(topicResults: [(topic: String, correct: Int, wrong: Int)]) -> String {
        switch game.phase {
        case .lostWrong:
            let maxWrong = game.board?.maxWrong ?? 3
            if let worst = topicResults.first(where: { $0.wrong > 0 }) {
                return "You used all \(maxWrong) lives. \(worst.topic) was toughest — \(worst.wrong) of \(worst.correct + worst.wrong) wrong. Try easier topics or a smaller board."
            }
            return "You used all \(maxWrong) lives. Try easier topics or a smaller board."
        case .lostStuck:
            return "No path to the goal — burned cells blocked the way. Try moving toward the goal early."
        default:
            return ""
        }
    }

    // MARK: - Topic Performance Bars

    private func topicPerformanceBars(topicResults: [(topic: String, correct: Int, wrong: Int)]) -> some View {
        let active = topicResults.filter { $0.correct + $0.wrong > 0 }
            .sorted { $0.wrong > $1.wrong }

        return VStack(alignment: .leading, spacing: 6) {
            ForEach(active, id: \.topic) { result in
                HStack(spacing: 8) {
                    Text(result.topic)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 80, alignment: .trailing)
                        .lineLimit(1)

                    GeometryReader { geo in
                        let total = result.correct + result.wrong
                        let greenWidth = total > 0 ? geo.size.width * CGFloat(result.correct) / CGFloat(total) : 0

                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(Color.green.opacity(0.7))
                                .frame(width: greenWidth)
                            Rectangle()
                                .fill(Color.red.opacity(0.5))
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                    }
                    .frame(height: 10)

                    Text("\(result.correct)/\(result.correct + result.wrong)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 30, alignment: .trailing)
                }
            }
        }
    }

    // MARK: - Post-Game Analysis

    private func fetchAnalysis() {
        guard !isAnalyzing, !game.fastGame else { return }
        isAnalyzing = true
        let won = game.phase == .won
        let boardSize = game.board?.size ?? game.boardSize
        let moves = game.moveCount
        let wrong = game.wrongCount
        let topicResults = computeTopicResults()

        Task {
            if QrossAI.isAvailable {
                postGameAnalysis = await QrossAI.analyzeGame(
                    won: won,
                    boardSize: boardSize,
                    moveCount: moves,
                    wrongCount: wrong,
                    topicResults: topicResults
                )
            }
            if postGameAnalysis == nil {
                postGameAnalysis = deterministicAnalysis(topicResults: topicResults, won: won)
            }
            isAnalyzing = false
        }
    }

    private func computeTopicResults() -> [(topic: String, correct: Int, wrong: Int)] {
        guard let board = game.board else { return [] }
        var results: [String: (correct: Int, wrong: Int)] = [:]
        for r in 0..<board.size {
            for c in 0..<board.size {
                let cell = board.cells[r][c]
                let topic = cell.topicColor
                var entry = results[topic, default: (correct: 0, wrong: 0)]
                switch cell.state {
                case .correct: entry.correct += 1
                case .wrong: entry.wrong += 1
                default: break
                }
                results[topic] = entry
            }
        }
        return results.map { (topic: $0.key, correct: $0.value.correct, wrong: $0.value.wrong) }
            .sorted { $0.wrong > $1.wrong }
    }

    private func deterministicAnalysis(topicResults: [(topic: String, correct: Int, wrong: Int)], won: Bool) -> String {
        let worst = topicResults.first(where: { $0.wrong > 0 })
        let best = topicResults.max(by: { $0.correct < $1.correct })
        if won {
            if let b = best, b.correct > 0 {
                return "Strong in \(b.topic)!" + (worst.map { " Work on \($0.topic)." } ?? "")
            }
            return "Great game!"
        } else {
            if let w = worst {
                return "\(w.topic) was tough — \(w.wrong) wrong. Try easier topics next time."
            }
            return "Better luck next time!"
        }
    }
}
