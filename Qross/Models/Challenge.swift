import Foundation

struct Choice: Codable, Identifiable {
    var id: String { text }
    let text: String
    let isCorrect: Bool
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
}
