import Foundation
import Observation

enum GamePhase {
    case setup
    case playing
    case won
    case lostWrong    // too many wrong answers
    case lostStuck    // no available moves
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
    var path: [CellPosition] = []
    var variant: GameVariant = .faceDown
    var selectedTopics: [Topic] = []
    var boardSize: Int = 5
    var cornerPair: CornerPair = .topLeftToBottomRight

    var score: Int {
        moveCount + (wrongCount * 2)
    }

    var minPossibleScore: Int {
        board?.size ?? boardSize  // diagonal = N moves
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
        path = []
        phase = .playing
    }

    // MARK: - Gameplay

    func availableCells() -> [CellPosition] {
        guard let board else { return [] }
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
        // Mark reachable untouched cells as available
        for pos in availableCells() {
            if board[pos].state == .untouched {
                board[pos].state = .available
            }
        }
        self.board = board
    }

    func answerCell(at position: CellPosition, choiceIndex: Int) {
        guard var board, phase == .playing else { return }
        let cell = board[position]
        let isCorrect = choiceIndex == cell.challenge.correctIndex
        let isCornerPick = currentPosition == nil  // choosing starting corner

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

            // Check win
            if position == board.endPosition {
                self.board = board
                phase = .won
                return
            }
        } else {
            board[position].state = .wrong
            wrongCount += 1

            // Check lose — too many wrong
            if wrongCount >= board.maxWrong {
                self.board = board
                phase = .lostWrong
                return
            }
        }

        self.board = board
        updateAvailability()

        // Check lose — stuck
        if availableCells().isEmpty && phase == .playing {
            phase = .lostStuck
        }
    }

    func reset() {
        board = nil
        phase = .setup
        currentPosition = nil
        wrongCount = 0
        moveCount = 0
        path = []
    }

    // MARK: - Share Card

    func shareText() -> String {
        guard let board else { return "" }
        let status = phase == .won ? "✅" : "❌"
        var text = "Qross \(board.size)×\(board.size) \(board.cornerPair.arrow) — \(moveCount) moves, \(wrongCount) miss \(status)\n"
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
