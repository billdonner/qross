import Foundation

struct TopicResult: Codable {
    let topic: String
    let correct: Int
    let wrong: Int

    var total: Int { correct + wrong }
    var accuracy: Double { total > 0 ? Double(correct) / Double(total) : 0 }
}

struct GameScore: Codable, Identifiable {
    var id: UUID = UUID()
    let date: Date
    let boardSize: Int
    let cornerPair: CornerPair
    let variant: String
    let mode: String
    let moves: Int
    let wrong: Int
    let hintPenalty: Int
    let won: Bool
    let topics: [String]
    let topicResults: [TopicResult]

    var total: Int { moves + (wrong * 2) + hintPenalty }
    var minPossible: Int {
        mode == "Double Cross" ? boardSize * 2 : boardSize
    }

    var rating: Rating {
        if !won { return .incomplete }
        let diff = total - minPossible
        switch diff {
        case 0: return .perfect
        case 1...2: return .excellent
        case 3...5: return .good
        default: return .completed
        }
    }

    enum Rating: String, Codable {
        case perfect = "Perfect"
        case excellent = "Excellent"
        case good = "Good"
        case completed = "Completed"
        case incomplete = "Incomplete"

        var emoji: String {
            switch self {
            case .perfect: return "🌟"
            case .excellent: return "⭐"
            case .good: return "👍"
            case .completed: return "✅"
            case .incomplete: return "❌"
            }
        }
    }
}

actor GameHistory {
    static let shared = GameHistory()
    private let key = "qross_game_history"

    func save(_ score: GameScore) {
        var all = loadAll()
        all.append(score)
        // Keep last 200 games
        if all.count > 200 { all = Array(all.suffix(200)) }
        if let data = try? JSONEncoder().encode(all) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func loadAll() -> [GameScore] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let scores = try? JSONDecoder().decode([GameScore].self, from: data) else {
            return []
        }
        return scores
    }

    var winRate: Double {
        let all = loadAll()
        guard !all.isEmpty else { return 0 }
        return Double(all.filter(\.won).count) / Double(all.count)
    }

    var currentStreak: Int {
        let all = loadAll().reversed()
        var streak = 0
        for score in all {
            if score.won { streak += 1 } else { break }
        }
        return streak
    }

    var bestStreak: Int {
        let all = loadAll()
        var best = 0
        var current = 0
        for score in all {
            if score.won {
                current += 1
                best = max(best, current)
            } else {
                current = 0
            }
        }
        return best
    }

    func statsByTopic() -> [String: (correct: Int, wrong: Int)] {
        let all = loadAll()
        var stats: [String: (correct: Int, wrong: Int)] = [:]
        for score in all {
            for tr in score.topicResults {
                var entry = stats[tr.topic, default: (correct: 0, wrong: 0)]
                entry.correct += tr.correct
                entry.wrong += tr.wrong
                stats[tr.topic] = entry
            }
        }
        return stats
    }
}
