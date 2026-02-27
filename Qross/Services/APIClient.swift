import Foundation

enum APIError: Error {
    case badURL, networkError(Error), decodingError(Error), serverError(Int)
}

/// Minimal card-engine API client for fetching trivia questions
struct QrossAPI {
    static let baseURL = "https://bd-card-engine.fly.dev"

    /// Fetch trivia categories with question counts
    static func fetchCategories() async throws -> [Topic] {
        let url = URL(string: "\(baseURL)/api/v1/trivia/categories")!
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw APIError.serverError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        let decoded = try JSONDecoder().decode(CategoriesResponse.self, from: data)
        return decoded.categories.map { cat in
            Topic(id: cat.name, name: cat.name, questionCount: cat.count)
        }
    }

    /// Fetch trivia questions for specific categories
    static func fetchQuestions(categories: [String]? = nil) async throws -> [Challenge] {
        let url = URL(string: "\(baseURL)/api/v1/trivia/gamedata")!
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw APIError.serverError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        let decoded = try JSONDecoder().decode(GameDataResponse.self, from: data)
        let selectedCats = categories.map(Set.init)
        return decoded.challenges.compactMap { item -> Challenge? in
            if let cats = selectedCats, !cats.contains(item.topic) { return nil }
            // Build choices from answers array + correct string
            let correctAnswer = item.correct
            let choices = item.answers.map { ans in
                Choice(text: ans, isCorrect: ans == correctAnswer)
            }
            let correctIndex = item.answers.firstIndex(of: correctAnswer) ?? 0
            return Challenge(
                id: UUID(uuidString: item.id) ?? UUID(),
                question: item.question,
                choices: choices,
                correctIndex: correctIndex,
                difficulty: .medium,
                topicId: item.topic,
                hint: nil,
                explanation: item.explanation
            )
        }
    }
}

// MARK: - API Response Models

private struct CategoriesResponse: Decodable {
    let categories: [CategoryItem]

    struct CategoryItem: Decodable {
        let name: String
        let count: Int
    }
}

private struct GameDataResponse: Decodable {
    let challenges: [ChallengeItem]

    struct ChallengeItem: Decodable {
        let id: String
        let topic: String
        let question: String
        let answers: [String]
        let correct: String
        let explanation: String?
    }
}
