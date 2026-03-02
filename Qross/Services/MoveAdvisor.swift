import FoundationModels
import Foundation

@Generable
struct MoveExplanation {
    @Guide(description: "One sentence explaining why this move is strategically good")
    var reason: String
}

final class MoveAdvisor {

    /// Runtime check — false on devices without Apple Intelligence
    static var isAvailable: Bool {
        SystemLanguageModel.default.isAvailable
    }

    /// Generate a one-sentence explanation for a pre-determined best move (chosen by BFS).
    func explainMove(
        board: Board,
        currentPosition: CellPosition,
        suggestedPosition: CellPosition,
        livesRemaining: Int
    ) async -> String? {
        guard Self.isAvailable else { return nil }

        let cell = board[suggestedPosition]
        let topic = cell.challenge.topicId
        let diff = cell.challenge.difficulty.rawValue
        let dir = directionLabel(from: currentPosition, to: suggestedPosition)
        let goalNote = goalAssessment(from: currentPosition, to: suggestedPosition, goal: board.endPosition)
        let stepsToGoal = board.shortestPath(from: suggestedPosition, to: board.endPosition).count

        let prompt = """
            \(board.size)×\(board.size) grid trivia game. Goal: \(cornerName(board.endPosition, gridSize: board.size)). \(livesRemaining) lives left.
            Best move: \(topic) (\(diff)) — \(dir), \(goalNote). \(stepsToGoal) steps to goal after this move.
            Explain in one sentence why this is a good strategic move.
            """

        let session = LanguageModelSession(
            model: .default,
            instructions: "Give concise Qross game strategy advice. No emoji. One sentence max. Be direct."
        )

        do {
            let response = try await session.respond(to: prompt, generating: MoveExplanation.self)
            let reason = response.content.reason.trimmingCharacters(in: .whitespacesAndNewlines)
            return reason.isEmpty ? nil : reason
        } catch {
            return nil
        }
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
