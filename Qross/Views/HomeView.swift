import SwiftUI

struct HomeView: View {
    @State private var game = GameState()
    @State private var gcManager = GameCenterManager()
    @State private var availableTopics: [Topic] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showGame = false
    @State private var showHowToPlay = false
    @State private var showAbout = false
    @State private var showStats = false
    @State private var showSettings = false
    @AppStorage("fastGame") private var fastGame = false
    @AppStorage("enableHaptics") private var enableHaptics = true
    @AppStorage("textSize") private var textSize = 1
    @AppStorage("qross_device_id") private var deviceId = ""
    @AppStorage("qross_player_id") private var playerId = ""
    @Environment(\.scenePhase) private var scenePhase
    @State private var isOffline = false
    @State private var showWelcomeConfetti = false
    @State private var backgroundedAt: Date?

    var body: some View {
        NavigationStack {
            ZStack {
                // Animated background grid
                gridBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Logo
                        VStack(spacing: 8) {
                            Text("Qross")
                                .font(.system(size: 56, weight: .black, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple, .pink],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            Text("Navigate. Answer. Conquer.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 8)

                        // Center icon
                        Image(systemName: "square.grid.3x3.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        // Main actions
                        VStack(spacing: 16) {
                        // Difficulty presets
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Quick Start")
                                .font(.subheadline.bold())
                                .foregroundStyle(.secondary)
                            HStack(spacing: 8) {
                                presetButton(
                                    label: "Quick Play",
                                    description: "Learn the ropes",
                                    size: 4, variant: .faceUp, mode: .single
                                )
                                presetButton(
                                    label: "Challenge",
                                    description: "Test your knowledge",
                                    size: 5, variant: .faceDown, mode: .single
                                )
                                presetButton(
                                    label: "Expert",
                                    description: "For seasoned players",
                                    size: 6, variant: .blind, mode: .doubleCross
                                )
                            }
                        }

                        // Topic selection
                        if !availableTopics.isEmpty {
                            topicPicker
                        }

                        // Play button
                        Button {
                            startGame()
                        } label: {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Play")
                            }
                            .font(.title3.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                game.selectedTopics.count >= 2
                                    ? LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                                    : LinearGradient(colors: [.gray, .gray], startPoint: .leading, endPoint: .trailing)
                            )
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(game.selectedTopics.count < 2 || isLoading)

                        if game.selectedTopics.count < 2 && !availableTopics.isEmpty {
                            Text("Select at least 2 topics to play")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }

                        if isLoading {
                            ProgressView("Loading questions...")
                        }

                        if isOffline {
                            HStack(spacing: 6) {
                                Image(systemName: "wifi.slash")
                                Text("Offline mode")
                            }
                            .font(.caption.bold())
                            .foregroundStyle(.orange)
                        }

                        if let error = errorMessage {
                            Text(error)
                                .font(.subheadline)
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(24)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal)

                    // Bottom links
                    HStack(spacing: 20) {
                        if gcManager.isAuthenticated {
                            Button {
                                gcManager.showLeaderboard()
                            } label: {
                                Label("Leaderboards", systemImage: "trophy")
                                    .font(.callout)
                            }
                        }

                        Button {
                            showStats = true
                        } label: {
                            Label("Stats", systemImage: "chart.bar")
                                .font(.callout)
                        }

                        Button {
                            showHowToPlay = true
                        } label: {
                            Label("How to Play", systemImage: "questionmark.circle")
                                .font(.callout)
                        }

                        Button {
                            showAbout = true
                        } label: {
                            Label("About", systemImage: "info.circle")
                                .font(.callout)
                        }
                    }
                    // Version
                    Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"))")
                        .font(.caption2)
                        .foregroundStyle(.quaternary)

                    .padding(.bottom, 16)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .overlay {
                if showWelcomeConfetti {
                    ConfettiView()
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                                showWelcomeConfetti = false
                            }
                        }
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .background {
                    backgroundedAt = Date()
                } else if newPhase == .active, !showGame {
                    if let bg = backgroundedAt, Date().timeIntervalSince(bg) > 30 * 60 {
                        showWelcomeConfetti = true
                    }
                    backgroundedAt = nil
                }
            }
            .fullScreenCover(isPresented: $showGame) {
                GamePlayView(game: game, onExit: {
                    showGame = false
                    game.reset()
                })
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(game: game)
            }
            .sheet(isPresented: $showHowToPlay) {
                HowToPlayView()
            }
            .sheet(isPresented: $showAbout) {
                AboutView()
            }
            .sheet(isPresented: $showStats) {
                StatsView()
            }
            .task {
                game.fastGame = fastGame
                gcManager.authenticate()
                await registerPlayerIfNeeded()
                await loadTopics()
            }
        }
    }

    // MARK: - Topic Picker

    private var topicPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Topics")
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(game.selectedTopics.count) selected")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(availableTopics) { topic in
                        let isSelected = game.selectedTopics.contains(topic)
                        let diffColor = topicDifficultyColor(topic)
                        Button {
                            if isSelected {
                                game.selectedTopics.removeAll { $0.id == topic.id }
                            } else {
                                game.selectedTopics.append(topic)
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Text(topic.name)
                                    .font(.subheadline.bold())
                                    .lineLimit(1)
                                Text("\(topic.questionCount)")
                                    .font(.caption)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(isSelected ? diffColor.opacity(0.2) : diffColor.opacity(0.08))
                            .foregroundStyle(isSelected ? diffColor : .secondary)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(isSelected ? diffColor : Color.clear, lineWidth: 2)
                            )
                        }
                    }
                }
            }
        }
    }

    private func topicDifficultyColor(_ topic: Topic) -> Color {
        switch topic.questionCount {
        case 400...: return .green
        case 200..<400: return .orange
        default: return .red
        }
    }

    // MARK: - Presets

    private func presetButton(label: String, description: String, size: Int, variant: GameVariant, mode: GameMode) -> some View {
        Button {
            game.boardSize = size
            game.variant = variant
            game.mode = mode
        } label: {
            VStack(spacing: 4) {
                Text(label)
                    .font(.caption.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                isPresetActive(size: size, variant: variant, mode: mode)
                    ? Color.blue.opacity(0.15) : Color(.secondarySystemBackground)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isPresetActive(size: size, variant: variant, mode: mode)
                            ? Color.blue : Color.clear,
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func isPresetActive(size: Int, variant: GameVariant, mode: GameMode) -> Bool {
        game.boardSize == size && game.variant == variant && game.mode == mode
    }

    // MARK: - Background Grid

    private var gridBackground: some View {
        GeometryReader { geo in
            let cellSize: CGFloat = 50
            let cols = Int(geo.size.width / cellSize) + 1
            let rows = Int(geo.size.height / cellSize) + 1
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(cellSize), spacing: 2), count: cols), spacing: 2) {
                ForEach(0..<(rows * cols), id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.primary.opacity(0.03))
                        .frame(height: cellSize)
                }
            }
        }
    }

    // MARK: - Actions

    private func loadTopics() async {
        do {
            let topics = try await QrossAPI.fetchCategories()
            availableTopics = topics.filter { $0.questionCount >= 20 }
            // Auto-select preferred default topics
            let preferredIds = ["Arts & Literature", "General Knowledge"]
            let defaults = availableTopics.filter { preferredIds.contains($0.name) }
            game.selectedTopics = defaults.isEmpty ? Array(availableTopics.prefix(2)) : defaults
        } catch {
            errorMessage = "Could not load topics. Check your connection."
        }
    }

    private func registerPlayerIfNeeded() async {
        // Generate persistent device ID on first launch
        if deviceId.isEmpty {
            deviceId = UUID().uuidString
        }
        // Register with server if we don't have a player ID yet
        if playerId.isEmpty {
            if let pid = try? await QrossAPI.registerPlayer(deviceId: deviceId) {
                playerId = pid
            }
        }
    }

    private func startGame() {
        isLoading = true
        errorMessage = nil
        isOffline = false
        Task {
            let topicIds = game.selectedTopics.map(\.id)
            let needed = game.boardSize * game.boardSize
            var questions: [Challenge] = []

            do {
                let pid = playerId.isEmpty ? nil : playerId
                let result = try await QrossAPI.fetchQuestions(
                    categories: topicIds,
                    playerId: pid,
                    count: needed
                )
                questions = result.challenges
                game.shareCode = result.shareCode
                game.freshCount = result.freshCount
                // Cache per-topic for offline use
                let byTopic = Dictionary(grouping: questions, by: \.topicId)
                for (tid, qs) in byTopic {
                    try? await QuestionCache.shared.save(questions: qs, forTopic: tid)
                }
            } catch {
                // Try loading from cache
                if await QuestionCache.shared.hasCached(topicIds: topicIds) {
                    var cached: [Challenge] = []
                    for tid in topicIds {
                        if let qs = await QuestionCache.shared.load(topicId: tid) {
                            cached.append(contentsOf: qs)
                        }
                    }
                    questions = cached
                    isOffline = true
                }
            }

            guard questions.count >= needed else {
                if isOffline && questions.isEmpty {
                    errorMessage = "No connection and no cached questions. Go online first."
                } else if questions.isEmpty {
                    errorMessage = "All questions seen! Select more topics or wait for new content."
                } else {
                    errorMessage = "Not enough questions (\(questions.count)/\(needed)). Select more topics."
                }
                isLoading = false
                return
            }
            game.startGame(questions: questions)
            isLoading = false
            showGame = true
        }
    }
}
