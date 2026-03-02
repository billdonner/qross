import SwiftUI

struct StatsView: View {
    @State private var games: [GameScore] = []
    @State private var winRate: Double = 0
    @State private var currentStreak: Int = 0
    @State private var bestStreak: Int = 0
    @State private var topicStats: [String: (correct: Int, wrong: Int)] = [:]

    var body: some View {
        NavigationStack {
            Group {
                if games.isEmpty {
                    ContentUnavailableView(
                        "No Games Yet",
                        systemImage: "gamecontroller",
                        description: Text("Play a game to see your stats here.")
                    )
                } else {
                    List {
                        summarySection
                        topicStrengthSection
                        recentGamesSection
                    }
                }
            }
            .navigationTitle("Stats")
            .task {
                await loadStats()
            }
        }
    }

    // MARK: - Summary

    private var summarySection: some View {
        Section("Summary") {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: 12) {
                summaryCell(value: "\(games.count)", label: "Played")
                summaryCell(value: "\(Int(winRate * 100))%", label: "Win Rate")
                summaryCell(value: "\(currentStreak)", label: "Streak")
                summaryCell(value: "\(bestStreak)", label: "Best")
            }
            .padding(.vertical, 4)
        }
    }

    private func summaryCell(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold().monospacedDigit())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Topic Strength

    private var topicStrengthSection: some View {
        Section("Topic Strength") {
            let sorted = topicStats.sorted { lhs, rhs in
                let lTotal = lhs.value.correct + lhs.value.wrong
                let rTotal = rhs.value.correct + rhs.value.wrong
                guard lTotal > 0 && rTotal > 0 else { return lTotal > rTotal }
                let lRate = Double(lhs.value.correct) / Double(lTotal)
                let rRate = Double(rhs.value.correct) / Double(rTotal)
                return lRate > rRate
            }

            ForEach(sorted, id: \.key) { topic, stats in
                let total = stats.correct + stats.wrong
                let accuracy = total > 0 ? Double(stats.correct) / Double(total) : 0

                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(topic)
                            .font(.callout)
                            .lineLimit(1)
                        Text("\(stats.correct)/\(total) correct")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(minWidth: 100, alignment: .leading)

                    Spacer()

                    GeometryReader { geo in
                        let greenWidth = geo.size.width * accuracy

                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.red.opacity(0.3))
                            Rectangle()
                                .fill(Color.green.opacity(0.7))
                                .frame(width: greenWidth)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    .frame(height: 12)

                    Text("\(Int(accuracy * 100))%")
                        .font(.caption.bold().monospacedDigit())
                        .frame(width: 36, alignment: .trailing)
                }
            }
        }
    }

    // MARK: - Recent Games

    private var recentGamesSection: some View {
        Section("Recent Games") {
            ForEach(games.suffix(20).reversed()) { game in
                HStack {
                    Text(game.rating.emoji)
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("\(game.boardSize)x\(game.boardSize)")
                                .font(.callout.bold())
                            Text(game.variant)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 1)
                                .background(Color.secondary.opacity(0.1))
                                .clipShape(Capsule())
                            if game.mode == "Double Cross" {
                                Text("2x")
                                    .font(.caption.bold())
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(Color.purple.opacity(0.15))
                                    .foregroundStyle(.purple)
                                    .clipShape(Capsule())
                            }
                        }
                        Text(game.date, style: .relative)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(game.total)")
                            .font(.callout.bold().monospacedDigit())
                            .foregroundStyle(game.won ? .green : .red)
                        Text(game.won ? "Won" : "Lost")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Load

    private func loadStats() async {
        games = await GameHistory.shared.loadAll()
        winRate = await GameHistory.shared.winRate
        currentStreak = await GameHistory.shared.currentStreak
        bestStreak = await GameHistory.shared.bestStreak
        topicStats = await GameHistory.shared.statsByTopic()
    }
}
