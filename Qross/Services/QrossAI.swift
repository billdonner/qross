import FoundationModels
import Foundation

// MARK: - Generable Structs

@Generable
struct AIHint {
    @Guide(description: "A brief, helpful hint that nudges toward the correct answer without giving it away")
    var hint: String
}

@Generable
struct AIExplanation {
    @Guide(description: "A brief explanation of why the correct answer is right")
    var explanation: String
}

@Generable
struct AIGameAnalysis {
    @Guide(description: "One or two sentences analyzing the player's performance and suggesting improvement")
    var analysis: String
}

@Generable
struct AIBoardPreview {
    @Guide(description: "One sentence previewing what to expect from this board's topic mix")
    var preview: String
}

// MARK: - AI Service

/// On-device AI features for Qross. All methods return nil when Apple Intelligence is unavailable.
final class QrossAI {

    static var isAvailable: Bool {
        SystemLanguageModel.default.isAvailable
    }

    // MARK: - Hint Generation

    static func generateHint(for challenge: Challenge) async -> String? {
        guard isAvailable else { return nil }

        let correctAnswer = challenge.choices[challenge.correctIndex].text
        let prompt = """
            Trivia question: \(challenge.question)
            Topic: \(challenge.topicId)
            Correct answer: \(correctAnswer)

            Give a brief hint that nudges toward the answer without revealing it.
            """

        let session = LanguageModelSession(
            model: .default,
            instructions: "Generate a short trivia hint. One sentence. No emoji. Do not mention the answer directly."
        )

        do {
            let response = try await session.respond(to: prompt, generating: AIHint.self)
            let hint = response.content.hint.trimmingCharacters(in: .whitespacesAndNewlines)
            return hint.isEmpty ? nil : hint
        } catch {
            return nil
        }
    }

    // MARK: - Explanation Generation

    static func generateExplanation(for challenge: Challenge) async -> String? {
        guard isAvailable else { return nil }

        let correctAnswer = challenge.choices[challenge.correctIndex].text
        let prompt = """
            Trivia question: \(challenge.question)
            Correct answer: \(correctAnswer)
            Topic: \(challenge.topicId)

            Briefly explain why this is the correct answer.
            """

        let session = LanguageModelSession(
            model: .default,
            instructions: "Explain a trivia answer. Two sentences max. Be educational. No emoji."
        )

        do {
            let response = try await session.respond(to: prompt, generating: AIExplanation.self)
            let explanation = response.content.explanation.trimmingCharacters(in: .whitespacesAndNewlines)
            return explanation.isEmpty ? nil : explanation
        } catch {
            return nil
        }
    }

    // MARK: - Post-Game Analysis

    static func analyzeGame(
        won: Bool,
        boardSize: Int,
        moveCount: Int,
        wrongCount: Int,
        topicResults: [(topic: String, correct: Int, wrong: Int)]
    ) async -> String? {
        guard isAvailable else { return nil }

        let outcomeStr = won ? "Won" : "Lost"
        var topicSummary = topicResults
            .map { "\($0.topic): \($0.correct) correct, \($0.wrong) wrong" }
            .joined(separator: "\n")
        if topicSummary.isEmpty { topicSummary = "No detailed data" }

        let prompt = """
            Qross game result: \(outcomeStr)
            Board: \(boardSize)×\(boardSize), \(moveCount) moves, \(wrongCount) wrong answers

            Performance by topic:
            \(topicSummary)

            Give a brief analysis of the player's performance. Note strengths and weaknesses.
            """

        let session = LanguageModelSession(
            model: .default,
            instructions: "Analyze a trivia game. One to two sentences. Encouraging but honest. No emoji."
        )

        do {
            let response = try await session.respond(to: prompt, generating: AIGameAnalysis.self)
            let analysis = response.content.analysis.trimmingCharacters(in: .whitespacesAndNewlines)
            return analysis.isEmpty ? nil : analysis
        } catch {
            return nil
        }
    }

    // MARK: - Board Preview

    static func previewBoard(
        boardSize: Int,
        topicCounts: [(topic: String, count: Int)]
    ) async -> String? {
        guard isAvailable else { return nil }

        let breakdown = topicCounts
            .map { "\($0.topic): \($0.count) cells" }
            .joined(separator: ", ")

        let prompt = """
            Qross \(boardSize)×\(boardSize) board preview.
            Topics: \(breakdown)

            Give a one-sentence preview of what the player should expect from this board.
            """

        let session = LanguageModelSession(
            model: .default,
            instructions: "Preview a trivia game board. One sentence. Be playful but informative. No emoji."
        )

        do {
            let response = try await session.respond(to: prompt, generating: AIBoardPreview.self)
            let preview = response.content.preview.trimmingCharacters(in: .whitespacesAndNewlines)
            return preview.isEmpty ? nil : preview
        } catch {
            return nil
        }
    }
}
