import Foundation

enum APIError: Error {
    case badURL, networkError(Error), decodingError(Error), serverError(Int)
}

/// Minimal cardzerver API client for fetching trivia questions
struct QrossAPI {
    static let baseURL = "https://bd-cardzerver.fly.dev"

    /// Fetch trivia categories with question counts
    static func fetchCategories() async throws -> [Topic] {
        let url = URL(string: "\(baseURL)/api/v1/trivia/categories?tier=free")!
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
        let url = URL(string: "\(baseURL)/api/v1/trivia/gamedata?tier=free")!
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
                difficulty: Challenge.estimateDifficulty(question: item.question, answers: item.answers),
                topicId: item.topic,
                hint: item.hint,
                explanation: item.explanation
            )
        }
    }

    /// Report a question — fire-and-forget, errors silently ignored
    static func reportQuestion(
        challengeId: String,
        topic: String?,
        question: String,
        reason: String = "inaccurate",
        detail: String? = nil
    ) {
        Task {
            guard let url = URL(string: "\(baseURL)/api/v1/reports") else { return }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            var body: [String: String] = [
                "app_id": "qross",
                "challenge_id": challengeId,
                "question_text": question,
                "reason": reason,
            ]
            if let topic { body["topic"] = topic }
            if let detail { body["detail"] = detail }

            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            _ = try? await URLSession.shared.data(for: request)
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
        let hint: String?
    }
}
