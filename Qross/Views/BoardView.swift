import SwiftUI

struct BoardView: View {
    @Bindable var game: GameState
    var topicColors: [String: Color]

    @State private var activeCell: CellPosition?
    @State private var showQuestion = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
                .padding(.horizontal)
                .padding(.top, 8)

            Spacer(minLength: 8)

            // Grid
            if let board = game.board {
                grid(board: board)
                    .padding(12)
            }

            Spacer(minLength: 8)

            // Lives
            livesBar
                .padding(.horizontal)
                .padding(.bottom, 8)
        }
        .overlay {
            if showQuestion, let pos = activeCell, let board = game.board {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { showQuestion = false }

                QuestionOverlay(
                    challenge: board[pos].challenge,
                    topicColor: topicColors[board[pos].topicColor] ?? .blue,
                    topicName: board[pos].topicColor,
                    onAnswer: { choiceIndex in
                        game.answerCell(at: pos, choiceIndex: choiceIndex)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            showQuestion = false
                            activeCell = nil
                        }
                    },
                    onDismiss: {
                        showQuestion = false
                        activeCell = nil
                    }
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3), value: showQuestion)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Qross")
                    .font(.title2.bold())
                if let board = game.board {
                    Text("\(board.size)×\(board.size) \(board.cornerPair.arrow)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text("\(game.moveCount) moves")
                    .font(.headline.monospacedDigit())
                Text("Score: \(game.score)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Grid

    private func grid(board: Board) -> some View {
        let spacing: CGFloat = 4
        let total = board.size * board.size
        return LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: board.size),
            spacing: spacing
        ) {
            ForEach(0..<total, id: \.self) { index in
                let row = index / board.size
                let col = index % board.size
                let pos = CellPosition(row: row, col: col)
                let cell = board[pos]
                CellView(
                    cell: cell,
                    topicColor: topicColors[cell.topicColor] ?? .blue,
                    variant: game.variant,
                    isStart: pos == board.startPosition,
                    isEnd: pos == board.endPosition,
                    onTap: {
                        activeCell = pos
                        showQuestion = true
                    }
                )
            }
        }
    }

    // MARK: - Lives Bar

    private var livesBar: some View {
        HStack {
            // Lives
            HStack(spacing: 4) {
                ForEach(0..<(game.board?.maxWrong ?? 3), id: \.self) { i in
                    Image(systemName: i < game.livesRemaining ? "heart.fill" : "heart")
                        .foregroundStyle(i < game.livesRemaining ? .red : .gray)
                        .font(.caption)
                }
            }

            Spacer()

            // Topic legend
            HStack(spacing: 8) {
                ForEach(game.selectedTopics.prefix(5)) { topic in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(topicColors[topic.id] ?? .blue)
                            .frame(width: 8, height: 8)
                        Text(topic.name)
                            .font(.caption2)
                            .lineLimit(1)
                    }
                }
            }
        }
    }
}
