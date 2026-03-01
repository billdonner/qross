import SwiftUI

struct BoardView: View {
    @Bindable var game: GameState
    var topicColors: [String: Color]
    var onQuit: (() -> Void)?

    @State private var activeCell: CellPosition?
    @State private var showQuestion = false
    @State private var showQuitConfirm = false
    @State private var suggestedPosition: CellPosition?
    @State private var suggestionReason: String?
    @State private var suggestedPath: Set<CellPosition> = []
    @State private var isLoadingSuggestion = false
    @State private var suggestionTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
                .padding(.horizontal)
                .padding(.top, 8)

            // AI Suggestion Banner
            suggestionBanner
                .padding(.horizontal)

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
                    },
                    onHintUsed: { cost in
                        game.useHint(cost: cost)
                    },
                    fastGame: game.fastGame
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3), value: showQuestion)
        .alert("Quit Game?", isPresented: $showQuitConfirm) {
            Button("Keep Playing", role: .cancel) { }
            Button("Quit", role: .destructive) { onQuit?() }
        } message: {
            Text("Your progress will be lost.")
        }
        .onChange(of: game.currentPosition) {
            fetchSuggestion()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack(spacing: 6) {
                    Text("Qross")
                        .font(.title2.bold())
                    if game.mode == .doubleCross {
                        Text("Leg \(game.leg) of 2")
                            .font(.caption.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.purple.opacity(0.2))
                            .foregroundStyle(.purple)
                            .clipShape(Capsule())
                    }
                }
                if let board = game.board {
                    if game.choosingCorner {
                        Text("\(board.size)×\(board.size) — Pick a corner!")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    } else if game.choosingSecondCorner {
                        Text("\(board.size)×\(board.size) — Pick your next target!")
                            .font(.caption)
                            .foregroundStyle(.purple)
                    } else {
                        Text("\(board.size)×\(board.size) \(board.cornerPair.arrow)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
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
                let isCorner = board.corners.contains(pos)
                let isSecondCornerCandidate: Bool = {
                    guard game.choosingSecondCorner else { return false }
                    let remaining = Board.remainingCorners(
                        start: board.startPosition, end: board.endPosition, gridSize: board.size
                    )
                    return remaining.contains(pos) && (cell.state == .available || cell.state == .untouched)
                }()
                let isEnd: Bool = {
                    if game.choosingCorner || game.choosingSecondCorner { return false }
                    return pos == board.endPosition
                }()
                CellView(
                    cell: cell,
                    topicColor: topicColors[cell.topicColor] ?? .blue,
                    variant: game.variant,
                    isEnd: isEnd,
                    isCornerPick: (game.choosingCorner && isCorner && cell.state == .available) || isSecondCornerCandidate,
                    isAISuggested: pos == suggestedPosition,
                    isOnSuggestedPath: suggestedPath.contains(pos),
                    onTap: {
                        suggestedPosition = nil
                        suggestionReason = nil
                        suggestedPath = []
                        if isSecondCornerCandidate {
                            // Second corner pick is just a selection — no question
                            game.selectSecondCorner(at: pos)
                        } else {
                            activeCell = pos
                            showQuestion = true
                        }
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

            if onQuit != nil {
                Button {
                    showQuitConfirm = true
                } label: {
                    Text("Quit")
                        .font(.caption.bold())
                        .foregroundStyle(.red)
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

    // MARK: - AI Suggestion Banner

    @ViewBuilder
    private var suggestionBanner: some View {
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            if !game.fastGame && game.phase == .playing
                && !game.choosingCorner && !game.choosingSecondCorner
                && (isLoadingSuggestion || suggestionReason != nil) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.purple)
                        .font(.caption)

                    if isLoadingSuggestion {
                        ProgressView()
                            .controlSize(.small)
                        Text("Thinking...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if let text = suggestionReason {
                        Text(text)
                            .font(.caption)
                            .foregroundStyle(.primary)
                            .lineLimit(3)
                    }

                    Spacer(minLength: 0)
                }
                .padding(8)
                .background(.purple.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                .transition(.opacity.combined(with: .move(edge: .top)))
                .animation(.easeInOut(duration: 0.3), value: suggestionReason)
                .animation(.easeInOut(duration: 0.3), value: isLoadingSuggestion)
            }
        }
        #endif
    }

    private func fetchSuggestion() {
        #if canImport(FoundationModels)
        guard #available(iOS 26, *) else { return }

        // Only fetch when Fast Game is off
        guard !game.fastGame else {
            suggestedPosition = nil
            suggestionReason = nil
            suggestedPath = []
            isLoadingSuggestion = false
            return
        }

        guard let board = game.board,
              let position = game.currentPosition,
              game.phase == .playing,
              !game.choosingCorner,
              !game.choosingSecondCorner else {
            suggestedPosition = nil
            suggestionReason = nil
            suggestedPath = []
            isLoadingSuggestion = false
            return
        }

        guard MoveAdvisor.isAvailable else { return }

        let available = game.availableCells()
        guard !available.isEmpty else {
            suggestedPosition = nil
            suggestionReason = nil
            suggestedPath = []
            isLoadingSuggestion = false
            return
        }

        // Cancel any in-flight suggestion
        suggestionTask?.cancel()
        isLoadingSuggestion = true
        suggestedPosition = nil
        suggestionReason = nil
        suggestedPath = []

        let advisor = MoveAdvisor()
        let variant = game.variant
        let lives = game.livesRemaining
        let moves = game.moveCount
        let wrong = game.wrongCount
        let score = game.score
        let leg = game.leg
        let mode = game.mode

        suggestionTask = Task {
            let result = await advisor.suggest(
                board: board,
                currentPosition: position,
                availableCells: available,
                variant: variant,
                livesRemaining: lives,
                moveCount: moves,
                wrongCount: wrong,
                score: score,
                leg: leg,
                mode: mode
            )
            guard !Task.isCancelled else { return }
            suggestedPosition = result?.position
            suggestionReason = result?.reason
            if let suggested = result?.position {
                let pathCells = board.shortestPath(from: suggested, to: board.endPosition)
                suggestedPath = Set(pathCells)
            } else {
                suggestedPath = []
            }
            isLoadingSuggestion = false
        }
        #endif
    }
}
