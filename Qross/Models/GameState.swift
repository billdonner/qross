import Foundation
import Observation

enum GamePhase {
    case setup
    case playing
    case won
    case lostWrong    // too many wrong answers
    case lostStuck    // no available moves
}

enum GameMode: String, CaseIterable, Identifiable {
    case single = "Single"
    case doubleCross = "Double Cross"

    var id: String { rawValue }
}

enum GameVariant: String, CaseIterable, Identifiable {
    case faceUp = "Face Up"
    case faceDown = "Face Down"
    case blind = "Blind"
    case concentration = "Concentration"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .faceUp: return "All questions visible — plan your route"
        case .faceDown: return "Only topic colors shown"
        case .blind: return "No colors, no questions — full fog of war"
        case .concentration: return "Match pairs before answering (even boards only)"
        }
    }
}

@Observable
final class GameState {
    var board: Board?
    var phase: GamePhase = .setup
    var currentPosition: CellPosition?
    var wrongCount: Int = 0
    var moveCount: Int = 0
    var hintPenalty: Int = 0
    var path: [CellPosition] = []
    var variant: GameVariant = .faceDown
    var mode: GameMode = .single
    var selectedTopics: [Topic] = []
    var boardSize: Int = 5
    var fastGame: Bool = false
    var cornerPair: CornerPair = .topLeftToBottomRight
    var leg: Int = 1
    var choosingSecondCorner: Bool = false

    var score: Int {
        moveCount + (wrongCount * 2) + hintPenalty
    }

    var minPossibleScore: Int {
        let n = board?.size ?? boardSize  // diagonal = N moves
        return mode == .doubleCross ? n * 2 : n
    }

    var livesRemaining: Int {
        (board?.maxWrong ?? 3) - wrongCount
    }

    /// True while player hasn't locked in a starting corner yet
    var choosingCorner: Bool {
        phase == .playing && currentPosition == nil
    }

    // MARK: - Setup

    func startGame(questions: [Challenge]) {
        let coloredTopics = TopicPalette.assign(to: selectedTopics)
        let seed: UInt64? = nil  // TODO: daily challenge seed
        var newBoard = Board.generate(
            size: boardSize,
            cornerPair: cornerPair,
            topics: coloredTopics,
            questions: questions,
            seed: seed
        )

        // Mark all 4 corners as available — player picks their start
        for corner in newBoard.corners {
            newBoard[corner].state = .available
        }

        board = newBoard
        currentPosition = nil
        wrongCount = 0
        moveCount = 0
        hintPenalty = 0
        path = []
        leg = 1
        choosingSecondCorner = false
        phase = .playing
    }

    // MARK: - Gameplay

    func availableCells() -> [CellPosition] {
        guard let board else { return [] }

        // Double Cross: choosing second leg target — only remaining corners
        if choosingSecondCorner {
            let remaining = Board.remainingCorners(
                start: board.startPosition, end: board.endPosition, gridSize: board.size
            )
            return remaining.filter { corner in
                let state = board[corner].state
                return state == .available || state == .untouched
            }
        }

        guard let pos = currentPosition else {
            // No move yet — all untried corners are available
            return board.corners.filter { corner in
                let state = board[corner].state
                return state == .available || state == .untouched
            }
        }
        return pos.neighbors(gridSize: board.size).filter { p in
            let cell = board[p]
            return cell.state == .untouched || cell.state == .available
        }
    }

    func updateAvailability() {
        guard var board else { return }
        // Reset available cells back to untouched (preserve correct/wrong)
        for r in 0..<board.size {
            for c in 0..<board.size {
                if board.cells[r][c].state == .available {
                    board.cells[r][c].state = .untouched
                }
            }
        }
        // Commit reset so availableCells() sees current state
        self.board = board
        // Mark reachable untouched cells as available
        for pos in availableCells() {
            if self.board![pos].state == .untouched {
                self.board![pos].state = .available
            }
        }
    }

    /// Select a corner as the leg 2 target (no question — just a pick)
    func selectSecondCorner(at position: CellPosition) {
        guard var board, phase == .playing, choosingSecondCorner else { return }
        board.endPosition = position
        choosingSecondCorner = false
        self.board = board
        updateAvailability()
    }

    func answerCell(at position: CellPosition, choiceIndex: Int) {
        guard var board, phase == .playing else { return }
        let cell = board[position]
        let isCorrect = choiceIndex == cell.challenge.correctIndex
        let isCornerPick = currentPosition == nil

        if isCorrect {
            board[position].state = .correct
            currentPosition = position
            moveCount += 1
            path.append(position)

            // First correct answer locks in start/end corners
            if isCornerPick {
                board.startPosition = position
                board.endPosition = Board.oppositeCorner(of: position, gridSize: board.size)
                board.cornerPair = Board.cornerPair(for: position, gridSize: board.size)
            }

            // Check win / leg transition
            if position == board.endPosition {
                if mode == .doubleCross && leg == 1 {
                    // Leg 1 complete — transition to leg 2
                    leg = 2
                    choosingSecondCorner = true
                    // Mark remaining corners as available for picking
                    let remaining = Board.remainingCorners(
                        start: board.startPosition, end: position, gridSize: board.size
                    )
                    for corner in remaining {
                        if board[corner].state == .untouched {
                            board[corner].state = .available
                        }
                    }
                    self.board = board
                    updateAvailability()
                    return
                } else {
                    // Single mode win, or Double Cross leg 2 win
                    self.board = board
                    phase = .won
                    saveGame()
                    return
                }
            }
        } else {
            board[position].state = .wrong
            wrongCount += 1

            // Check lose — burned corner during pick: no viable corner left
            // A corner is viable only if its diagonally opposite corner is also unburned
            if isCornerPick {
                let hasViableCorner = board.corners.contains { corner in
                    let state = board[corner].state
                    guard state != .wrong else { return false }
                    let opposite = Board.oppositeCorner(of: corner, gridSize: board.size)
                    return board[opposite].state != .wrong
                }
                if !hasViableCorner {
                    self.board = board
                    phase = .lostStuck
                    saveGame()
                    return
                }
            }

            // Check lose — missed the goal corner (burned, can never win)
            if !isCornerPick && position == board.endPosition {
                self.board = board
                phase = .lostStuck
                saveGame()
                return
            }

            // Check lose — too many wrong
            if wrongCount >= board.maxWrong {
                self.board = board
                phase = .lostWrong
                saveGame()
                return
            }
        }

        self.board = board
        updateAvailability()

        // Check lose — stuck
        if availableCells().isEmpty && phase == .playing {
            phase = .lostStuck
            saveGame()
        }
    }

    /// Apply a hint penalty to the score
    func useHint(cost: Int) {
        hintPenalty += cost
    }

    // MARK: - Save Game

    private func saveGame() {
        guard let board else { return }
        let topicResults = computeTopicResults(board: board)
        let gameScore = GameScore(
            date: Date(),
            boardSize: board.size,
            cornerPair: board.cornerPair,
            variant: variant.rawValue,
            mode: mode.rawValue,
            moves: moveCount,
            wrong: wrongCount,
            hintPenalty: hintPenalty,
            won: phase == .won,
            topics: board.topics,
            topicResults: topicResults
        )
        Task { await GameHistory.shared.save(gameScore) }
    }

    private func computeTopicResults(board: Board) -> [TopicResult] {
        var results: [String: (correct: Int, wrong: Int)] = [:]
        for r in 0..<board.size {
            for c in 0..<board.size {
                let cell = board.cells[r][c]
                let topic = cell.topicColor
                var entry = results[topic, default: (correct: 0, wrong: 0)]
                switch cell.state {
                case .correct: entry.correct += 1
                case .wrong: entry.wrong += 1
                default: break
                }
                results[topic] = entry
            }
        }
        return results.map { TopicResult(topic: $0.key, correct: $0.value.correct, wrong: $0.value.wrong) }
    }

    func reset() {
        board = nil
        phase = .setup
        currentPosition = nil
        wrongCount = 0
        moveCount = 0
        hintPenalty = 0
        path = []
        leg = 1
        choosingSecondCorner = false
    }

    // MARK: - Share Card

    func shareText() -> String {
        guard let board else { return "" }
        let status = phase == .won ? "✅" : "❌"
        let hintStr = hintPenalty > 0 ? ", \(hintPenalty) hints" : ""
        let modeLabel = mode == .doubleCross ? " Double Cross" : ""
        var text = "Qross\(modeLabel) \(board.size)×\(board.size) \(board.cornerPair.arrow) — \(moveCount) moves, \(wrongCount) miss\(hintStr) \(status)\n"
        for r in 0..<board.size {
            for c in 0..<board.size {
                let cell = board.cells[r][c]
                switch cell.state {
                case .correct: text += "🟩"
                case .wrong: text += "🟥"
                default: text += "⬜"
                }
            }
            text += "\n"
        }
        return text
    }
}
