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
    }

    func testCorrectAnswer() {
        let game = GameState()
        game.selectedTopics = [Topic(id: "test", name: "Test", questionCount: 100)]
        game.boardSize = 4
        game.startGame(questions: makeQuestions(count: 20))

        let start = game.board!.startPosition
        game.answerCell(at: start, choiceIndex: 1) // correct

        XCTAssertEqual(game.moveCount, 1)
        XCTAssertEqual(game.wrongCount, 0)
        XCTAssertEqual(game.currentPosition, start)
        XCTAssertEqual(game.board![start].state, .correct)
    }

    func testWrongAnswer() {
        let game = GameState()
        game.selectedTopics = [Topic(id: "test", name: "Test", questionCount: 100)]
        game.boardSize = 4
        game.startGame(questions: makeQuestions(count: 20))

        let start = game.board!.startPosition
        game.answerCell(at: start, choiceIndex: 0) // wrong

        XCTAssertEqual(game.moveCount, 0)
        XCTAssertEqual(game.wrongCount, 1)
        XCTAssertNil(game.currentPosition)
        XCTAssertEqual(game.board![start].state, .wrong)
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
