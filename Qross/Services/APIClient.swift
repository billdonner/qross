import Foundation

enum APIError: Error {
    case badURL, networkError(Error), decodingError(Error), serverError(Int)
}

/// Result from fetching questions — includes session metadata when player_id is provided
struct FetchResult {
    let challenges: [Challenge]
    let sessionId: String?
    let shareCode: String?
    let freshCount: Int?
    let totalAvailable: Int?
}

/// Challenge metadata stored on the server after a game
struct ChallengeData: Codable {
    let boardSize: Int
    let lockedCorner: [Int]?  // [row, col] or nil if corner not locked
    let score: ChallengerScore

    struct ChallengerScore: Codable {
        let moves: Int
        let wrong: Int
        let hints: Int
        let won: Bool
    }
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
        playerId: String? = nil,
        count: Int? = nil
    ) async throws -> FetchResult {
        guard var components = URLComponents(string: "\(baseURL)/api/v1/trivia/gamedata") else {
            throw APIError.badURL
        }
        var queryItems = [URLQueryItem(name: "tier", value: "free")]
        if let cats = categories, !cats.isEmpty {
            queryItems.append(URLQueryItem(name: "categories", value: cats.joined(separator: ",")))
        }
        if let pid = playerId, !pid.isEmpty {
            queryItems.append(URLQueryItem(name: "player_id", value: pid))
            queryItems.append(URLQueryItem(name: "app_id", value: "qross"))
        }
        if let c = count {
            queryItems.append(URLQueryItem(name: "count", value: String(c)))
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
            sessionId: decoded.session_id,
            shareCode: decoded.share_code,
            freshCount: decoded.fresh_count,
            totalAvailable: decoded.total_available
        )
    }

    // MARK: - Challenge

    /// Save challenge metadata to the server after a game.
    static func saveChallenge(sessionId: String, data: ChallengeData) {
        Task {
            guard let url = URL(string: "\(baseURL)/api/v1/sessions/\(sessionId)") else { return }
            var request = URLRequest(url: url)
            request.httpMethod = "PATCH"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let body: [String: Any] = [
                "properties": [
                    "challenge": [
                        "board_size": data.boardSize,
                        "locked_corner": data.lockedCorner as Any,
                        "score": [
                            "moves": data.score.moves,
                            "wrong": data.score.wrong,
                            "hints": data.score.hints,
                            "won": data.score.won,
                        ],
                    ]
                ]
            ]
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            _ = try? await URLSession.shared.data(for: request)
        }
    }

    /// Fetch a challenge by share code. Returns questions + challenger metadata.
    static func fetchChallenge(shareCode: String) async throws -> ChallengeResult {
        guard let url = URL(string: "\(baseURL)/api/v1/sessions/\(shareCode.uppercased())") else {
            throw APIError.badURL
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw APIError.serverError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        let decoded = try JSONDecoder().decode(ChallengeResponse.self, from: data)

        let challenges = decoded.challenges.compactMap { item -> Challenge? in
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

        return ChallengeResult(
            challenges: challenges,
            challengeData: decoded.challenge
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
    let session_id: String?
    let share_code: String?
    let fresh_count: Int?
    let total_available: Int?
}

/// Result from fetching a challenge by share code
struct ChallengeResult {
    let challenges: [Challenge]
    let challengeData: ChallengeMetadata?
}

private struct ChallengeResponse: Decodable {
    let challenges: [ChallengeItem]
    let challenge: ChallengeMetadata?
}

struct ChallengeMetadata: Decodable {
    let board_size: Int?
    let locked_corner: [Int]?
    let score: ChallengerScoreResponse?

    struct ChallengerScoreResponse: Decodable {
        let moves: Int
        let wrong: Int
        let hints: Int
        let won: Bool
    }
}

private struct ChallengeItem: Decodable {
    let id: String
    let topic: String
    let question: String
    let answers: [String]
    let correct: String
    let explanation: String?
    let hint: String?
    let ai_difficulty: String?
}
