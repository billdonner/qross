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
        return decoded.decks.flatMap { deck -> [Challenge] in
            if let cats = selectedCats, !cats.contains(deck.title) { return [] }
            return deck.cards.map { card in
                let choices = (card.properties.choices ?? []).map {
                    Choice(text: $0.text, isCorrect: $0.isCorrect)
                }
                return Challenge(
                    id: UUID(uuidString: card.id) ?? UUID(),
                    question: card.question,
                    choices: choices,
                    correctIndex: card.properties.correctIndex ?? 0,
                    difficulty: Challenge.Difficulty(rawValue: card.difficulty) ?? .medium,
                    topicId: deck.title,
                    hint: card.properties.hint,
                    explanation: card.properties.explanation
                )
            }
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
    let decks: [DeckItem]

    struct DeckItem: Decodable {
        let title: String
        let cards: [CardItem]
    }

    struct CardItem: Decodable {
        let id: String
        let question: String
        let difficulty: String
        let properties: CardProperties
    }

    struct CardProperties: Decodable {
        let choices: [ChoiceItem]?
        let correctIndex: Int?
        let hint: String?
        let explanation: String?

        enum CodingKeys: String, CodingKey {
            case choices, correctIndex = "correct_index", hint, explanation
        }
    }

    struct ChoiceItem: Decodable {
        let text: String
        let isCorrect: Bool
    }
}
