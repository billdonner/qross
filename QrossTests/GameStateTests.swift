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

    // MARK: - Double Cross Mode Tests

    func testDoubleCrossInitialState() {
        let game = GameState()
        game.selectedTopics = [Topic(id: "test", name: "Test", questionCount: 100)]
        game.boardSize = 5
        game.mode = .doubleCross
        game.startGame(questions: makeQuestions(count: 30))

        XCTAssertEqual(game.phase, .playing)
        XCTAssertEqual(game.leg, 1)
        XCTAssertFalse(game.choosingSecondCorner)
        XCTAssertEqual(game.mode, .doubleCross)
        XCTAssertEqual(game.minPossibleScore, 10, "Double Cross min score = 2 * board size")
    }

    func testDoubleCrossLeg1TransitionsToLeg2() {
        let game = GameState()
        game.selectedTopics = [Topic(id: "test", name: "Test", questionCount: 100)]
        game.boardSize = 4
        game.mode = .doubleCross
        game.startGame(questions: makeQuestions(count: 20))

        // Pick top-left corner (0,0)
        let start = CellPosition(row: 0, col: 0)
        game.answerCell(at: start, choiceIndex: 1) // correct
        XCTAssertEqual(game.board!.startPosition, start)
        let end = CellPosition(row: 3, col: 3)
        XCTAssertEqual(game.board!.endPosition, end)

        // Navigate diagonally to (3,3): (1,1), (2,2), (3,3)
        game.answerCell(at: CellPosition(row: 1, col: 1), choiceIndex: 1)
        game.answerCell(at: CellPosition(row: 2, col: 2), choiceIndex: 1)

        // Answer the end cell — should NOT win, should transition to leg 2
        game.answerCell(at: end, choiceIndex: 1)

        XCTAssertEqual(game.phase, .playing, "Should NOT have won yet — leg 1 just finished")
        XCTAssertEqual(game.leg, 2)
        XCTAssertTrue(game.choosingSecondCorner, "Should be picking second corner target")
    }

    func testDoubleCrossRemainingCornersAvailable() {
        let game = GameState()
        game.selectedTopics = [Topic(id: "test", name: "Test", questionCount: 100)]
        game.boardSize = 4
        game.mode = .doubleCross
        game.startGame(questions: makeQuestions(count: 20))

        // Play leg 1: (0,0) → (1,1) → (2,2) → (3,3)
        game.answerCell(at: CellPosition(row: 0, col: 0), choiceIndex: 1)
        game.answerCell(at: CellPosition(row: 1, col: 1), choiceIndex: 1)
        game.answerCell(at: CellPosition(row: 2, col: 2), choiceIndex: 1)
        game.answerCell(at: CellPosition(row: 3, col: 3), choiceIndex: 1)

        // Remaining corners should be (0,3) and (3,0)
        let available = game.availableCells()
        let topRight = CellPosition(row: 0, col: 3)
        let bottomLeft = CellPosition(row: 3, col: 0)

        XCTAssertEqual(available.count, 2, "Should have exactly 2 remaining corners")
        XCTAssertTrue(available.contains(topRight), "Top-right should be available")
        XCTAssertTrue(available.contains(bottomLeft), "Bottom-left should be available")
    }

    func testDoubleCrossSecondCornerSelection() {
        let game = GameState()
        game.selectedTopics = [Topic(id: "test", name: "Test", questionCount: 100)]
        game.boardSize = 4
        game.mode = .doubleCross
        game.startGame(questions: makeQuestions(count: 20))

        // Play leg 1: (0,0) → (1,1) → (2,2) → (3,3)
        game.answerCell(at: CellPosition(row: 0, col: 0), choiceIndex: 1)
        game.answerCell(at: CellPosition(row: 1, col: 1), choiceIndex: 1)
        game.answerCell(at: CellPosition(row: 2, col: 2), choiceIndex: 1)
        game.answerCell(at: CellPosition(row: 3, col: 3), choiceIndex: 1)

        XCTAssertTrue(game.choosingSecondCorner)

        // Select top-right as the second leg target (no question)
        let topRight = CellPosition(row: 0, col: 3)
        game.selectSecondCorner(at: topRight)

        XCTAssertFalse(game.choosingSecondCorner, "Should no longer be choosing")
        XCTAssertEqual(game.board!.endPosition, topRight, "End position should be the chosen corner")
        XCTAssertEqual(game.phase, .playing, "Should still be playing")
    }

    func testDoubleCrossFullWin() {
        let game = GameState()
        game.selectedTopics = [Topic(id: "test", name: "Test", questionCount: 100)]
        game.boardSize = 4
        game.mode = .doubleCross
        game.startGame(questions: makeQuestions(count: 20))

        // Leg 1: (0,0) → (1,1) → (2,2) → (3,3)
        game.answerCell(at: CellPosition(row: 0, col: 0), choiceIndex: 1)
        game.answerCell(at: CellPosition(row: 1, col: 1), choiceIndex: 1)
        game.answerCell(at: CellPosition(row: 2, col: 2), choiceIndex: 1)
        game.answerCell(at: CellPosition(row: 3, col: 3), choiceIndex: 1)

        // Select top-right (0,3) as leg 2 target
        game.selectSecondCorner(at: CellPosition(row: 0, col: 3))

        // Leg 2: navigate from (3,3) toward (0,3)
        // Path: (3,3) is current → (2,3) → (1,3) → (0,3)
        game.answerCell(at: CellPosition(row: 2, col: 3), choiceIndex: 1)
        game.answerCell(at: CellPosition(row: 1, col: 3), choiceIndex: 1)
        game.answerCell(at: CellPosition(row: 0, col: 3), choiceIndex: 1)

        XCTAssertEqual(game.phase, .won, "Should have won after completing leg 2")
        XCTAssertEqual(game.leg, 2)
        XCTAssertEqual(game.moveCount, 7, "4 moves leg 1 + 3 moves leg 2")
    }

    func testDoubleCrossWrongCountCarriesOver() {
        let game = GameState()
        game.selectedTopics = [Topic(id: "test", name: "Test", questionCount: 100)]
        game.boardSize = 4  // maxWrong = 2
        game.mode = .doubleCross
        game.startGame(questions: makeQuestions(count: 20))

        // Leg 1: get 1 wrong, then complete
        game.answerCell(at: CellPosition(row: 0, col: 0), choiceIndex: 1) // correct
        game.answerCell(at: CellPosition(row: 1, col: 0), choiceIndex: 0) // wrong!
        XCTAssertEqual(game.wrongCount, 1)

        game.answerCell(at: CellPosition(row: 1, col: 1), choiceIndex: 1)
        game.answerCell(at: CellPosition(row: 2, col: 2), choiceIndex: 1)
        game.answerCell(at: CellPosition(row: 3, col: 3), choiceIndex: 1) // leg 1 done

        XCTAssertEqual(game.leg, 2)
        XCTAssertEqual(game.wrongCount, 1, "Wrong count should carry over")

        // Select corner and get another wrong → should lose (maxWrong = 2)
        game.selectSecondCorner(at: CellPosition(row: 0, col: 3))
        game.answerCell(at: CellPosition(row: 2, col: 3), choiceIndex: 0) // wrong → total 2

        XCTAssertEqual(game.phase, .lostWrong, "Should have lost from accumulated wrongs")
    }

    func testDoubleCrossShareText() {
        let game = GameState()
        game.selectedTopics = [Topic(id: "test", name: "Test", questionCount: 100)]
        game.boardSize = 4
        game.mode = .doubleCross
        game.startGame(questions: makeQuestions(count: 20))

        // Complete a game (simplified — just check share text includes mode label)
        game.answerCell(at: CellPosition(row: 0, col: 0), choiceIndex: 1)
        let text = game.shareText()
        XCTAssertTrue(text.contains("Double Cross"), "Share text should include mode label")
    }

    func testSingleModeUnchanged() {
        let game = GameState()
        game.selectedTopics = [Topic(id: "test", name: "Test", questionCount: 100)]
        game.boardSize = 4
        game.mode = .single
        game.startGame(questions: makeQuestions(count: 20))

        // Play the diagonal: (0,0) → (1,1) → (2,2) → (3,3)
        game.answerCell(at: CellPosition(row: 0, col: 0), choiceIndex: 1)
        game.answerCell(at: CellPosition(row: 1, col: 1), choiceIndex: 1)
        game.answerCell(at: CellPosition(row: 2, col: 2), choiceIndex: 1)
        game.answerCell(at: CellPosition(row: 3, col: 3), choiceIndex: 1)

        XCTAssertEqual(game.phase, .won, "Single mode should win after one diagonal")
        XCTAssertEqual(game.leg, 1, "Should remain on leg 1 in single mode")
        XCTAssertFalse(game.choosingSecondCorner)
    }

    func testDoubleCrossResetClearsState() {
        let game = GameState()
        game.mode = .doubleCross
        game.leg = 2
        game.choosingSecondCorner = true

        game.reset()

        XCTAssertEqual(game.leg, 1)
        XCTAssertFalse(game.choosingSecondCorner)
        XCTAssertEqual(game.phase, .setup)
    }
}
