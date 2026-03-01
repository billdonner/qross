#if canImport(FoundationModels)
import FoundationModels
import Foundation

@available(iOS 26, *)
@Generable
struct MoveSuggestion {
    @Guide(description: "The letter label of the recommended cell (A, B, C, etc.)")
    var cellLabel: String
    @Guide(description: "One sentence explaining why this is the best move")
    var reason: String
}

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
    ) async -> (position: CellPosition, reason: String)? {
        guard Self.isAvailable, !availableCells.isEmpty else { return nil }

        // Build label-to-position mapping alongside the prompt
        var labelMap: [String: CellPosition] = [:]
        let prompt = buildPrompt(
            board: board,
            currentPosition: currentPosition,
            availableCells: availableCells,
            livesRemaining: livesRemaining,
            mode: mode,
            leg: leg,
            labelMap: &labelMap
        )

        let session = LanguageModelSession(
            model: .default,
            instructions: """
                You are a concise strategy advisor for Qross, a grid trivia game. \
                The player navigates from one corner to the opposite by answering \
                trivia questions. Pick the best available cell and explain why in one sentence. \
                Consider distance to goal and topic difficulty. Do not use emoji. Be direct.
                """
        )

        do {
            let response = try await session.respond(to: prompt, generating: MoveSuggestion.self)
            let suggestion = response.content
            let label = suggestion.cellLabel.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            guard let position = labelMap[label] else { return nil }
            let reason = suggestion.reason.trimmingCharacters(in: .whitespacesAndNewlines)
            return reason.isEmpty ? nil : (position: position, reason: reason)
        } catch {
            return nil
        }
    }

    // MARK: - Prompt Builder

    private func buildPrompt(
        board: Board,
        currentPosition: CellPosition,
        availableCells: [CellPosition],
        livesRemaining: Int,
        mode: GameMode,
        leg: Int,
        labelMap: inout [String: CellPosition]
    ) -> String {
        let goal = board.endPosition
        let labels = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

        var lines: [String] = []
        lines.append("\(board.size)×\(board.size) grid. Goal: \(cornerName(goal, gridSize: board.size)). \(livesRemaining) lives left.")
        if mode == .doubleCross {
            lines.append("Mode: Double Cross, Leg \(leg) of 2.")
        }
        lines.append("")
        lines.append("Available moves:")

        for (i, pos) in availableCells.enumerated() {
            guard i < labels.count else { break }
            let letter = String(labels[labels.index(labels.startIndex, offsetBy: i)])
            labelMap[letter] = pos

            let cell = board[pos]
            let topic = cell.challenge.topicId
            let diff = cell.challenge.difficulty.rawValue
            let dir = directionLabel(from: currentPosition, to: pos)
            let goalNote = goalAssessment(from: currentPosition, to: pos, goal: goal)

            lines.append("\(letter)) \(topic) (\(diff)) — \(dir), \(goalNote)")
        }

        lines.append("")
        lines.append("Which cell is the best move? Consider distance to goal and topic difficulty.")

        return lines.joined(separator: "\n")
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
#endif
