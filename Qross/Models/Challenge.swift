import Foundation

struct Choice: Codable, Identifiable {
    let id: Int
    let text: String
}

struct Challenge: Identifiable, Codable {
    let id: UUID
    let question: String
    let choices: [Choice]
    let correctIndex: Int
    let difficulty: Difficulty
    let topicId: String
    let hint: String?
    let explanation: String?

    enum Difficulty: String, Codable, CaseIterable {
        case easy, medium, hard
    }

    /// Estimate difficulty from question text and answer choices (heuristic, no AI needed).
    static func estimateDifficulty(question: String, answers: [String]) -> Difficulty {
        var score = 0

        // Longer questions tend to be harder
        if question.count > 120 { score += 2 }
        else if question.count > 70 { score += 1 }

        // Long answer texts suggest harder disambiguation
        let avgLen = answers.reduce(0) { $0 + $1.count } / max(answers.count, 1)
        if avgLen > 25 { score += 1 }

        // Shared words across answers = harder to distinguish
        let wordSets = answers.map { Set($0.lowercased().split(separator: " ").map(String.init)) }
        if wordSets.count >= 2 {
            var shared = 0
            for i in 0..<wordSets.count {
                for j in (i+1)..<wordSets.count {
                    shared += wordSets[i].intersection(wordSets[j]).count
                }
            }
            if shared > 4 { score += 2 }
            else if shared > 2 { score += 1 }
        }

        // Negation questions are harder
        let q = question.lowercased()
        if q.contains("not ") || q.contains("except") || q.contains("least") {
            score += 1
        }

        if score >= 4 { return .hard }
        if score >= 2 { return .medium }
        return .easy
    }
}
