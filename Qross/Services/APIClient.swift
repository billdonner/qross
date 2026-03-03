import Foundation

enum APIError: Error {
    case badURL, networkError(Error), decodingError(Error), serverError(Int)
}

/// Result from fetching questions — includes session metadata when player_id is provided
struct FetchResult {
    let challenges: [Challenge]
    let shareCode: String?
    let freshCount: Int?
    let totalAvailable: Int?
}

/// Minimal cardzerver API client for fetching trivia questions
struct QrossAPI {
    static let baseURL = "https://bd-cardzerver.fly.dev"

    // MARK: - Player Identity

    /// Register or upsert a player by device ID. Returns the server-assigned player UUID.
    static func registerPlayer(deviceId: String, displayName: String? = nil) async throws -> String {
        guard let url = URL(string: "\(baseURL)/api/v1/players") else {
            throw APIError.badURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: String] = ["device_id": deviceId]
        if let displayName { body["display_name"] = displayName }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw APIError.serverError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        let decoded = try JSONDecoder().decode(PlayerResponse.self, from: data)
        return decoded.id
    }

    // MARK: - Categories

    /// Fetch trivia categories with question counts
    static func fetchCategories() async throws -> [Topic] {
        guard let url = URL(string: "\(baseURL)/api/v1/trivia/categories?tier=free") else {
            throw APIError.badURL
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw APIError.serverError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        let decoded = try JSONDecoder().decode(CategoriesResponse.self, from: data)
        return decoded.categories.map { cat in
            Topic(id: cat.name, name: cat.name, questionCount: cat.count)
        }
    }

    // MARK: - Questions

    /// Fetch trivia questions, optionally with player-aware deduplication.
    /// When `playerId` is provided, the server excludes previously seen cards
    /// and returns session metadata (share code, fresh count).
    static func fetchQuestions(
        categories: [String]? = nil,
        playerId: String? = nil
    ) async throws -> FetchResult {
        var components = URLComponents(string: "\(baseURL)/api/v1/trivia/gamedata")!
        var queryItems = [URLQueryItem(name: "tier", value: "free")]
        if let cats = categories, !cats.isEmpty {
            queryItems.append(URLQueryItem(name: "categories", value: cats.joined(separator: ",")))
        }
        if let pid = playerId {
            queryItems.append(URLQueryItem(name: "player_id", value: pid))
            queryItems.append(URLQueryItem(name: "app_id", value: "qross"))
        }
        components.queryItems = queryItems
        guard let url = components.url else {
            throw APIError.badURL
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw APIError.serverError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        let decoded = try JSONDecoder().decode(GameDataResponse.self, from: data)
        let challenges = decoded.challenges.compactMap { item -> Challenge? in
            // Skip questions with missing or insufficient answers
            guard item.answers.count >= 2, !item.correct.isEmpty,
                  item.answers.contains(item.correct) else { return nil }
            let choices = item.answers.enumerated().map { index, ans in
                Choice(id: index, text: ans)
            }
            let correctIndex = item.answers.firstIndex(of: item.correct) ?? 0
            return Challenge(
                id: UUID(uuidString: item.id) ?? UUID(),
                question: item.question,
                choices: choices,
                correctIndex: correctIndex,
                difficulty: Challenge.Difficulty(rawValue: item.ai_difficulty?.trimmingCharacters(in: CharacterSet(charactersIn: "\"")) ?? "")
                    ?? Challenge.estimateDifficulty(question: item.question, answers: item.answers),
                topicId: item.topic,
                hint: item.hint?.isEmpty == true ? nil : item.hint,
                explanation: item.explanation?.isEmpty == true ? nil : item.explanation
            )
        }
        return FetchResult(
            challenges: challenges,
            shareCode: decoded.share_code,
            freshCount: decoded.fresh_count,
            totalAvailable: decoded.total_available
        )
    }

    // MARK: - Reports

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

private struct PlayerResponse: Decodable {
    let id: String
}

private struct CategoriesResponse: Decodable {
    let categories: [CategoryItem]

    struct CategoryItem: Decodable {
        let name: String
        let count: Int
    }
}

private struct GameDataResponse: Decodable {
    let challenges: [ChallengeItem]
    // Session metadata (present when player_id was provided)
    let share_code: String?
    let fresh_count: Int?
    let total_available: Int?

    struct ChallengeItem: Decodable {
        let id: String
        let topic: String
        let question: String
        let answers: [String]
        let correct: String
        let explanation: String?
        let hint: String?
        let ai_difficulty: String?
    }
}
