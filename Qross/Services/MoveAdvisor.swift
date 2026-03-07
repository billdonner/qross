import FoundationModels
import Foundation

@Generable
struct MoveExplanation {
    @Guide(description: "One sentence explaining why this move is strategically good")
    var reason: String
}

/// Risk level for a suggested move
enum MoveRisk: String {
    case safe = "Safe"
    case caution = "Caution"
    case risky = "Risky"

    var icon: String {
        switch self {
        case .safe: return "checkmark.shield"
        case .caution: return "exclamationmark.triangle"
        case .risky: return "flame"
        }
    }
}

/// Scored move candidate with strategic analysis
struct ScoredMove {
    let position: CellPosition
    let pathToGoal: [CellPosition]
    let stepsToGoal: Int
    let difficulty: Challenge.Difficulty
    let topicId: String
    let escapeRoutes: Int       // available moves after taking this step
    let risk: MoveRisk
    let score: Double           // lower = better
}

final class MoveAdvisor {

    /// Runtime check — false on devices without Apple Intelligence
    static var isAvailable: Bool {
        SystemLanguageModel.default.isAvailable
    }

    // MARK: - Smart Move Selection

    /// Evaluate all available moves and return the best one with full analysis.
    static func bestMove(
        board: Board,
        currentPosition: CellPosition,
        availableCells: [CellPosition],
        livesRemaining: Int
    ) -> ScoredMove? {
        guard !availableCells.isEmpty else { return nil }

        let scored = availableCells.map { candidate in
            scoreMove(
                board: board,
                from: currentPosition,
                to: candidate,
                livesRemaining: livesRemaining
            )
        }

        // Sort by score (lower is better)
        return scored.min(by: { $0.score < $1.score })
    }

    /// Score a single candidate move considering path length, difficulty, escape routes, and lives.
    private static func scoreMove(
        board: Board,
        from: CellPosition,
        to: CellPosition,
        livesRemaining: Int
    ) -> ScoredMove {
        let cell = board[to]
        let difficulty = cell.challenge.difficulty
        let pathToGoal = board.shortestPath(from: to, to: board.endPosition)
        let stepsToGoal = pathToGoal.count

        // Count escape routes: how many moves available after taking this step
        let escapeRoutes = to.neighbors(gridSize: board.size).filter { neighbor in
            let state = board[neighbor].state
            return (state == .untouched || state == .available) && neighbor != from
        }.count

        // Difficulty penalty — higher when lives are low
        let difficultyWeight: Double
        switch difficulty {
        case .easy:   difficultyWeight = 0.0
        case .medium: difficultyWeight = 1.0
        case .hard:   difficultyWeight = 2.0
        }
        let lifePressure = livesRemaining <= 2 ? 2.0 : (livesRemaining <= 4 ? 1.0 : 0.5)

        // Dead-end penalty — heavily penalize moves that leave few options
        let escapePenalty: Double
        switch escapeRoutes {
        case 0:  escapePenalty = 10.0  // dead end (only way is back)
        case 1:  escapePenalty = 3.0   // bottleneck
        case 2:  escapePenalty = 1.0   // narrow
        default: escapePenalty = 0.0   // comfortable
        }

        // Path length is the primary score component
        let pathScore = Double(stepsToGoal == 0 ? 100 : stepsToGoal)

        let totalScore = pathScore
            + (difficultyWeight * lifePressure)
            + escapePenalty

        // Risk assessment
        let risk: MoveRisk
        if escapeRoutes <= 1 && livesRemaining <= 2 {
            risk = .risky
        } else if difficulty == .hard && livesRemaining <= 3 {
            risk = .risky
        } else if escapeRoutes <= 1 || (difficulty == .hard && livesRemaining <= 5) {
            risk = .caution
        } else if difficulty == .medium && livesRemaining <= 2 {
            risk = .caution
        } else {
            risk = .safe
        }

        return ScoredMove(
            position: to,
            pathToGoal: pathToGoal,
            stepsToGoal: stepsToGoal,
            difficulty: difficulty,
            topicId: cell.challenge.topicId,
            escapeRoutes: escapeRoutes,
            risk: risk,
            score: totalScore
        )
    }

    // MARK: - AI Explanation

    /// Generate a one-sentence explanation for a scored move.
    func explainMove(
        board: Board,
        currentPosition: CellPosition,
        move: ScoredMove,
        livesRemaining: Int,
        alternativeCount: Int
    ) async -> String? {
        guard Self.isAvailable else { return nil }

        let dir = directionLabel(from: currentPosition, to: move.position)
        let goalNote = goalAssessment(from: currentPosition, to: move.position, goal: board.endPosition)

        let escapeNote: String
        switch move.escapeRoutes {
        case 0: escapeNote = "Dead end — only way is back."
        case 1: escapeNote = "Bottleneck — only 1 exit after this move."
        case 2: escapeNote = "Narrow — 2 exits after this move."
        default: escapeNote = "\(move.escapeRoutes) exits after this move."
        }

        let riskNote: String
        switch move.risk {
        case .safe: riskNote = "Low risk."
        case .caution: riskNote = "Moderate risk — proceed carefully."
        case .risky: riskNote = "High risk — this could be dangerous."
        }

        let prompt = """
            \(board.size)×\(board.size) grid trivia game. Goal: \(cornerName(board.endPosition, gridSize: board.size)). \(livesRemaining) lives left.
            Best move: \(move.topicId) (\(move.difficulty.rawValue)) — \(dir), \(goalNote). \(move.stepsToGoal) steps to goal.
            \(escapeNote) \(riskNote)
            \(alternativeCount) other moves available.
            Explain in one sentence why this is the best strategic choice right now.
            """

        let session = LanguageModelSession(
            model: .default,
            instructions: "Give concise Qross game strategy advice. No emoji. One sentence max. Be direct. Mention risk or escape routes only when relevant."
        )

        do {
            let response = try await session.respond(to: prompt, generating: MoveExplanation.self)
            let reason = response.content.reason.trimmingCharacters(in: .whitespacesAndNewlines)
            return reason.isEmpty ? nil : reason
        } catch {
            return nil
        }
    }

    // MARK: - Deterministic Fallback

    /// Build a fallback reason string without AI.
    static func fallbackReason(for move: ScoredMove) -> String {
        var parts: [String] = []
        parts.append("\(move.topicId) (\(move.difficulty.rawValue))")
        parts.append("\(move.stepsToGoal) steps to goal")

        if move.escapeRoutes <= 1 {
            parts.append("bottleneck ahead")
        }

        return parts.joined(separator: " — ")
    }

    // MARK: - Helpers

    private func directionLabel(from: CellPosition, to: CellPosition) -> String {
        let dr = to.row - from.row
        let dc = to.col - from.col

        var vertical = ""
        if dr < 0 { vertical = "up" }
        else if dr > 0 { vertical = "down" }

        var horizontal = ""
        if dc < 0 { horizontal = "left" }
        else if dc > 0 { horizontal = "right" }

        if vertical.isEmpty && horizontal.isEmpty { return "same position" }
        if vertical.isEmpty { return horizontal }
        if horizontal.isEmpty { return vertical }

        return "diagonally \(vertical)-\(horizontal)"
    }

    private func goalAssessment(from: CellPosition, to: CellPosition, goal: CellPosition) -> String {
        let currentDist = abs(goal.row - from.row) + abs(goal.col - from.col)
        let newDist = abs(goal.row - to.row) + abs(goal.col - to.col)

        if newDist < currentDist { return "moves toward goal" }
        if newDist > currentDist { return "moves away from goal" }
        return "same distance to goal"
    }

    private func cornerName(_ pos: CellPosition, gridSize: Int) -> String {
        let last = gridSize - 1
        switch (pos.row, pos.col) {
        case (0, 0): return "top-left corner"
        case (0, let c) where c == last: return "top-right corner"
        case (let r, 0) where r == last: return "bottom-left corner"
        case (let r, let c) where r == last && c == last: return "bottom-right corner"
        default: return "row \(pos.row), col \(pos.col)"
        }
    }
}
