import Foundation

struct GameScore: Codable {
    let date: Date
    let boardSize: Int
    let cornerPair: CornerPair
    let variant: String
    let moves: Int
    let wrong: Int
    let won: Bool
    let topics: [String]

    var total: Int { moves + (wrong * 2) }
    var minPossible: Int { boardSize }

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

    enum Rating: String {
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
