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
    @State private var boardPreview: String?
    @State private var isLoadingPreview = false

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
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
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
        .task {
            if !game.fastGame, let board = game.board {
                await fetchBoardPreview(board: board)
            }
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
                            .font(.subheadline.bold())
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
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                    } else if game.choosingSecondCorner {
                        Text("\(board.size)×\(board.size) — Pick your next target!")
                            .font(.subheadline)
                            .foregroundStyle(.purple)
                    } else {
                        Text("\(board.size)×\(board.size) \(board.cornerPair.arrow)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text("\(game.moveCount) moves")
                    .font(.headline.monospacedDigit())
                Text("Score: \(game.score)")
                    .font(.subheadline)
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
        VStack(spacing: 10) {
            // Lives + Quit
            HStack {
                HStack(spacing: 6) {
                    ForEach(0..<(game.board?.maxWrong ?? 3), id: \.self) { i in
                        Image(systemName: i < game.livesRemaining ? "heart.fill" : "heart")
                            .foregroundStyle(i < game.livesRemaining ? .red : .gray.opacity(0.5))
                            .font(.body)
                    }
                }

                Spacer()

                if onQuit != nil {
                    Button {
                        showQuitConfirm = true
                    } label: {
                        Text("Quit")
                            .font(.callout.bold())
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(Color.red.opacity(0.12))
                            .foregroundStyle(.red)
                            .clipShape(Capsule())
                    }
                }
            }

            // Difficulty legend
            HStack(spacing: 16) {
                ForEach(Challenge.Difficulty.allCases, id: \.rawValue) { diff in
                    HStack(spacing: 5) {
                        Circle()
                            .fill(difficultyLegendColor(diff))
                            .frame(width: 10, height: 10)
                        Text(diff.rawValue.capitalized)
                            .font(.subheadline)
                    }
                }
                Spacer()
            }
        }
    }

    // MARK: - AI Suggestion Banner

    @ViewBuilder
    private var suggestionBanner: some View {
        if !game.fastGame && game.phase == .playing {
            if game.choosingCorner, (isLoadingPreview || boardPreview != nil) {
                // Board preview during corner selection
                aiBanner(
                    icon: "eye",
                    loading: isLoadingPreview,
                    loadingText: "Analyzing board...",
                    text: boardPreview
                )
            } else if !game.choosingCorner && !game.choosingSecondCorner
                        && (isLoadingSuggestion || suggestionReason != nil) {
                // Move suggestion during gameplay
                aiBanner(
                    icon: "sparkles",
                    loading: isLoadingSuggestion,
                    loadingText: "Thinking...",
                    text: suggestionReason
                )
            }
        }
    }

    private func aiBanner(icon: String, loading: Bool, loadingText: String, text: String?) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.purple)
                .font(.subheadline)

            if loading {
                ProgressView()
                    .controlSize(.small)
                Text(loadingText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if let text {
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(3)
            }

            Spacer(minLength: 0)
        }
        .padding(8)
        .background(.purple.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private func fetchSuggestion() {
        // Only suggest when Fast Game is off
        guard !game.fastGame else {
            clearSuggestion()
            return
        }

        guard let board = game.board,
              let position = game.currentPosition,
              game.phase == .playing,
              !game.choosingCorner,
              !game.choosingSecondCorner else {
            clearSuggestion()
            return
        }

        // BFS optimal path from current position to goal
        let pathCells = board.shortestPath(from: position, to: board.endPosition)
        guard let firstStep = pathCells.first else {
            clearSuggestion()
            return
        }

        // Verify first step is actually available to the player
        let available = game.availableCells()
        guard available.contains(firstStep) else {
            clearSuggestion()
            return
        }

        // Cancel any in-flight AI explanation
        suggestionTask?.cancel()

        // Set path and position immediately (BFS is instant)
        suggestedPosition = firstStep
        suggestedPath = Set(pathCells)

        // Deterministic fallback reason
        let cell = board[firstStep]
        let fallbackReason = "\(cell.challenge.topicId) (\(cell.challenge.difficulty.rawValue)) — \(pathCells.count) steps to goal"

        // AI-enhanced reason (devices with Apple Intelligence)
        if MoveAdvisor.isAvailable {
            isLoadingSuggestion = true
            suggestionReason = nil
            let advisor = MoveAdvisor()
            let lives = game.livesRemaining
            suggestionTask = Task {
                let reason = await advisor.explainMove(
                    board: board,
                    currentPosition: position,
                    suggestedPosition: firstStep,
                    livesRemaining: lives
                )
                guard !Task.isCancelled else { return }
                suggestionReason = reason ?? fallbackReason
                isLoadingSuggestion = false
            }
        } else {
            // No Apple Intelligence — use deterministic reason
            suggestionReason = fallbackReason
            isLoadingSuggestion = false
        }
    }

    private func clearSuggestion() {
        suggestedPosition = nil
        suggestionReason = nil
        suggestedPath = []
        isLoadingSuggestion = false
    }

    private func difficultyLegendColor(_ difficulty: Challenge.Difficulty) -> Color {
        switch difficulty {
        case .easy:   return .green
        case .medium: return .orange
        case .hard:   return .red
        }
    }

    // MARK: - Board Preview

    private func fetchBoardPreview(board: Board) async {
        isLoadingPreview = true

        var counts: [String: Int] = [:]
        for r in 0..<board.size {
            for c in 0..<board.size {
                counts[board.cells[r][c].topicColor, default: 0] += 1
            }
        }
        let topicCounts = counts.map { (topic: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }

        if QrossAI.isAvailable {
            boardPreview = await QrossAI.previewBoard(
                boardSize: board.size,
                topicCounts: topicCounts
            )
        }
        if boardPreview == nil {
            // Deterministic fallback
            let dominant = topicCounts.first?.topic ?? "trivia"
            boardPreview = "This board is heavy on \(dominant) — pick your corner wisely!"
        }
        isLoadingPreview = false
    }
}
