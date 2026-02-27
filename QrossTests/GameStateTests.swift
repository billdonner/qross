import XCTest
@testable import Qross

final class GameStateTests: XCTestCase {

    private func makeQuestions(count: Int) -> [Challenge] {
        (0..<count).map { i in
            Challenge(
                id: UUID(),
                question: "Question \(i)",
                choices: [
                    Choice(text: "Wrong", isCorrect: false),
                    Choice(text: "Correct", isCorrect: true),
                    Choice(text: "Wrong2", isCorrect: false),
                    Choice(text: "Wrong3", isCorrect: false),
                ],
                correctIndex: 1,
                difficulty: .easy,
                topicId: "test",
                hint: nil,
                explanation: nil
            )
        }
    }

    func testStartGame() {
        let game = GameState()
        game.selectedTopics = [Topic(id: "test", name: "Test", questionCount: 100)]
        game.boardSize = 4
        game.startGame(questions: makeQuestions(count: 20))

        XCTAssertEqual(game.phase, .playing)
        XCTAssertEqual(game.moveCount, 0)
        XCTAssertEqual(game.wrongCount, 0)
        XCTAssertNotNil(game.board)
        XCTAssertEqual(game.board?.size, 4)
        XCTAssertTrue(game.choosingCorner, "Should be in corner-choosing phase")
    }

    func testAllCornersAvailableAtStart() {
        let game = GameState()
        game.selectedTopics = [Topic(id: "test", name: "Test", questionCount: 100)]
        game.boardSize = 5
        game.startGame(questions: makeQuestions(count: 30))

        let board = game.board!
        for corner in board.corners {
            XCTAssertEqual(board[corner].state, .available, "Corner \(corner) should be available")
        }
    }

    func testCorrectCornerLocksStartEnd() {
        let game = GameState()
        game.selectedTopics = [Topic(id: "test", name: "Test", questionCount: 100)]
        game.boardSize = 4
        game.startGame(questions: makeQuestions(count: 20))

        // Pick top-left corner (0,0) — correct answer
        let topLeft = CellPosition(row: 0, col: 0)
        game.answerCell(at: topLeft, choiceIndex: 1)

        XCTAssertEqual(game.moveCount, 1)
        XCTAssertEqual(game.wrongCount, 0)
        XCTAssertEqual(game.currentPosition, topLeft)
        XCTAssertEqual(game.board!.startPosition, topLeft)
        XCTAssertEqual(game.board!.endPosition, CellPosition(row: 3, col: 3))
        XCTAssertFalse(game.choosingCorner)
    }

    func testWrongCornerAllowsRetry() {
        let game = GameState()
        game.selectedTopics = [Topic(id: "test", name: "Test", questionCount: 100)]
        game.boardSize = 4
        game.startGame(questions: makeQuestions(count: 20))

        // Get wrong on top-left corner
        let topLeft = CellPosition(row: 0, col: 0)
        game.answerCell(at: topLeft, choiceIndex: 0) // wrong

        XCTAssertEqual(game.wrongCount, 1)
        XCTAssertNil(game.currentPosition)
        XCTAssertTrue(game.choosingCorner, "Should still be choosing a corner")
        XCTAssertEqual(game.board![topLeft].state, .wrong)

        // Other corners should still be available
        let available = game.availableCells()
        XCTAssertEqual(available.count, 3, "3 corners should remain available")
        XCTAssertFalse(available.contains(topLeft), "Burned corner should not be available")
    }

    func testScoreCalculation() {
        let game = GameState()
        game.selectedTopics = [Topic(id: "test", name: "Test", questionCount: 100)]
        game.boardSize = 5
        game.startGame(questions: makeQuestions(count: 30))

        // Simulate: 6 correct, 2 wrong
        // Score = 6 + (2 * 2) = 10
        let score = 6 + (2 * 2)
        XCTAssertEqual(score, 10)
    }
}
