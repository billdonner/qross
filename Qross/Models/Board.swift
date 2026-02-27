import Foundation

/// A position on the grid
struct CellPosition: Hashable, Codable {
    let row: Int
    let col: Int

    /// All 8-connected neighbors within bounds
    func neighbors(gridSize: Int) -> [CellPosition] {
        var result: [CellPosition] = []
        for dr in -1...1 {
            for dc in -1...1 {
                if dr == 0 && dc == 0 { continue }
                let r = row + dr, c = col + dc
                if r >= 0 && r < gridSize && c >= 0 && c < gridSize {
                    result.append(CellPosition(row: r, col: c))
                }
            }
        }
        return result
    }
}

/// The state of a single cell
enum CellState: Codable {
    case untouched
    case available    // adjacent to current position, tappable
    case correct      // answered correctly
    case wrong        // answered incorrectly (burned)
}

/// A cell on the board
struct Cell: Identifiable, Codable {
    var id: String { "\(position.row)-\(position.col)" }
    let position: CellPosition
    let challenge: Challenge
    let topicColor: String  // topic ID for color lookup
    var state: CellState = .untouched
}

/// Start/end corner configuration
enum CornerPair: String, Codable, CaseIterable, Identifiable {
    case topLeftToBottomRight = "Classic"
    case topRightToBottomLeft = "Reverse"
    case bottomLeftToTopRight = "Uphill"
    case bottomRightToTopLeft = "Downhill"

    var id: String { rawValue }

    func positions(gridSize: Int) -> (start: CellPosition, end: CellPosition) {
        let last = gridSize - 1
        switch self {
        case .topLeftToBottomRight:
            return (CellPosition(row: 0, col: 0), CellPosition(row: last, col: last))
        case .topRightToBottomLeft:
            return (CellPosition(row: 0, col: last), CellPosition(row: last, col: 0))
        case .bottomLeftToTopRight:
            return (CellPosition(row: last, col: 0), CellPosition(row: 0, col: last))
        case .bottomRightToTopLeft:
            return (CellPosition(row: last, col: last), CellPosition(row: 0, col: 0))
        }
    }

    /// Emoji arrow for display
    var arrow: String {
        switch self {
        case .topLeftToBottomRight: return "↘"
        case .topRightToBottomLeft: return "↙"
        case .bottomLeftToTopRight: return "↗"
        case .bottomRightToTopLeft: return "↖"
        }
    }
}

/// The full game board
struct Board: Codable {
    let size: Int
    var cells: [[Cell]]  // [row][col]
    let startPosition: CellPosition
    let endPosition: CellPosition
    let cornerPair: CornerPair
    let topics: [String]  // topic IDs used

    /// Max wrong answers allowed for this board size
    var maxWrong: Int {
        switch size {
        case 4: return 2
        case 5: return 3
        case 6: return 4
        case 7: return 5
        default: return 6
        }
    }

    /// Generate a board from questions and settings
    static func generate(
        size: Int,
        cornerPair: CornerPair,
        topics: [Topic],
        questions: [Challenge],
        seed: UInt64? = nil
    ) -> Board {
        var rng: RandomNumberGenerator = seed.map { SeededRNG(seed: $0) } ?? SystemRandomNumberGenerator() as RandomNumberGenerator
        let topicIds = topics.map(\.id)
        let totalCells = size * size

        // Distribute questions across cells, balanced by topic
        var pool = questions.shuffled(using: &rng)
        var assigned: [Challenge] = []
        // Round-robin by topic to balance
        var byTopic: [String: [Challenge]] = [:]
        for q in pool {
            byTopic[q.topicId, default: []].append(q)
        }
        var topicCycle = topicIds.makeIterator()
        while assigned.count < totalCells {
            if topicCycle.next() == nil {
                topicCycle = topicIds.makeIterator()
            }
            // Find next topic with remaining questions
            var found = false
            for tid in topicIds {
                if assigned.count >= totalCells { break }
                if var qs = byTopic[tid], !qs.isEmpty {
                    assigned.append(qs.removeFirst())
                    byTopic[tid] = qs
                    found = true
                }
            }
            if !found { break }
        }

        // Fill remaining with whatever's left if needed
        while assigned.count < totalCells && !pool.isEmpty {
            assigned.append(pool.removeFirst())
        }

        // Build grid
        var cells: [[Cell]] = []
        var idx = 0
        for r in 0..<size {
            var row: [Cell] = []
            for c in 0..<size {
                let challenge = idx < assigned.count
                    ? assigned[idx]
                    : Challenge(id: UUID(), question: "?", choices: [], correctIndex: 0,
                               difficulty: .easy, topicId: topicIds.first ?? "", hint: nil, explanation: nil)
                row.append(Cell(
                    position: CellPosition(row: r, col: c),
                    challenge: challenge,
                    topicColor: challenge.topicId
                ))
                idx += 1
            }
            cells.append(row)
        }

        let positions = cornerPair.positions(gridSize: size)
        return Board(
            size: size,
            cells: cells,
            startPosition: positions.start,
            endPosition: positions.end,
            cornerPair: cornerPair,
            topics: topicIds
        )
    }

    subscript(pos: CellPosition) -> Cell {
        get { cells[pos.row][pos.col] }
        set { cells[pos.row][pos.col] = newValue }
    }
}

/// Deterministic RNG for daily challenges / seeded boards
struct SeededRNG: RandomNumberGenerator {
    var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9e3779b97f4a7c15
        var z = state
        z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
        z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
        return z ^ (z >> 31)
    }
}
