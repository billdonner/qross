#if canImport(FoundationModels)
import FoundationModels
import Foundation

@available(iOS 26, *)
final class MoveAdvisor {

    static var isAvailable: Bool {
        SystemLanguageModel.default.isAvailable
    }

    func suggest(
        board: Board,
        currentPosition: CellPosition,
        availableCells: [CellPosition],
        variant: GameVariant,
        livesRemaining: Int,
        moveCount: Int,
        wrongCount: Int,
        score: Int,
        leg: Int,
        mode: GameMode
    ) async -> String? {
        guard Self.isAvailable, !availableCells.isEmpty else { return nil }

        let session = LanguageModelSession(
            model: .default,
            instructions: """
                You are a concise strategy advisor for Qross, a grid trivia game. \
                The player navigates from one corner to the opposite by answering \
                trivia questions. Give a 1-2 sentence recommendation for the best \
                next move. Consider topic difficulty, distance to goal, and remaining \
                lives. Do not use emoji. Be direct.
                """
        )

        let prompt = buildPrompt(
            board: board,
            currentPosition: currentPosition,
            availableCells: availableCells,
            variant: variant,
            livesRemaining: livesRemaining,
            moveCount: moveCount,
            wrongCount: wrongCount,
            score: score,
            leg: leg,
            mode: mode
        )

        do {
            let response = try await session.respond(to: prompt)
            let text = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            return text.isEmpty ? nil : text
        } catch {
            return nil
        }
    }

    // MARK: - Prompt Builder

    private func buildPrompt(
        board: Board,
        currentPosition: CellPosition,
        availableCells: [CellPosition],
        variant: GameVariant,
        livesRemaining: Int,
        moveCount: Int,
        wrongCount: Int,
        score: Int,
        leg: Int,
        mode: GameMode
    ) -> String {
        let goal = board.endPosition
        let goalDist = abs(goal.row - currentPosition.row) + abs(goal.col - currentPosition.col)

        var lines: [String] = []
        lines.append("Board: \(board.size)x\(board.size), Goal: (\(goal.row),\(goal.col))")
        lines.append("Current: (\(currentPosition.row),\(currentPosition.col)), Distance to goal: \(goalDist)")
        if mode == .doubleCross {
            lines.append("Mode: Double Cross, Leg \(leg) of 2")
        }
        lines.append("Lives: \(livesRemaining), Moves: \(moveCount), Wrong: \(wrongCount), Score: \(score)")
        lines.append("")
        lines.append("Available moves:")

        for pos in availableCells {
            let cell = board[pos]
            let dist = abs(goal.row - pos.row) + abs(goal.col - pos.col)
            let topic = cell.challenge.topicId
            let diff = cell.challenge.difficulty.rawValue
            lines.append("  (\(pos.row),\(pos.col)) topic=\"\(topic)\" diff=\(diff) dist=\(dist)")
        }

        lines.append("")
        lines.append("Board state:")
        for r in 0..<board.size {
            var row = "  "
            for c in 0..<board.size {
                let pos = CellPosition(row: r, col: c)
                let cell = board[pos]
                if pos == currentPosition {
                    row += "O"
                } else if availableCells.contains(pos) {
                    row += "?"
                } else {
                    switch cell.state {
                    case .correct: row += "O"
                    case .wrong: row += "X"
                    case .untouched, .available: row += "."
                    }
                }
            }
            lines.append(row)
        }

        return lines.joined(separator: "\n")
    }
}
#endif
