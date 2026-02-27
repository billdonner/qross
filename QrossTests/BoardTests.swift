import XCTest
@testable import Qross

final class BoardTests: XCTestCase {

    func testCellPositionNeighbors() {
        let pos = CellPosition(row: 0, col: 0)
        let neighbors = pos.neighbors(gridSize: 5)
        // Top-left corner should have 3 neighbors
        XCTAssertEqual(neighbors.count, 3)
    }

    func testCellPositionCenterNeighbors() {
        let pos = CellPosition(row: 2, col: 2)
        let neighbors = pos.neighbors(gridSize: 5)
        // Center cell should have 8 neighbors
        XCTAssertEqual(neighbors.count, 8)
    }

    func testCornerPairPositions() {
        let classic = CornerPair.topLeftToBottomRight.positions(gridSize: 5)
        XCTAssertEqual(classic.start, CellPosition(row: 0, col: 0))
        XCTAssertEqual(classic.end, CellPosition(row: 4, col: 4))

        let reverse = CornerPair.topRightToBottomLeft.positions(gridSize: 5)
        XCTAssertEqual(reverse.start, CellPosition(row: 0, col: 4))
        XCTAssertEqual(reverse.end, CellPosition(row: 4, col: 0))
    }

    func testMaxWrongByBoardSize() {
        // Create minimal boards to check maxWrong
        let topics = [Topic(id: "test", name: "Test", questionCount: 100)]
        let questions = (0..<100).map { i in
            Challenge(
                id: UUID(),
                question: "Q\(i)",
                choices: [Choice(text: "A", isCorrect: true)],
                correctIndex: 0,
                difficulty: .easy,
                topicId: "test",
                hint: nil,
                explanation: nil
            )
        }

        let b4 = Board.generate(size: 4, cornerPair: .topLeftToBottomRight, topics: topics, questions: questions)
        XCTAssertEqual(b4.maxWrong, 2)

        let b5 = Board.generate(size: 5, cornerPair: .topLeftToBottomRight, topics: topics, questions: questions)
        XCTAssertEqual(b5.maxWrong, 3)

        let b8 = Board.generate(size: 8, cornerPair: .topLeftToBottomRight, topics: topics, questions: questions)
        XCTAssertEqual(b8.maxWrong, 6)
    }
}
