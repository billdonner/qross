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
    @AppStorage("fastGame") private var fastGame = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Animated background grid
                gridBackground
                    .ignoresSafeArea()

                VStack(spacing: 32) {
                    Spacer()

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

                    Spacer()

                    // Main actions
                    VStack(spacing: 16) {
                        // Board size picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Board Size")
                                .font(.subheadline.bold())
                                .foregroundStyle(.secondary)
                            Picker("Size", selection: $game.boardSize) {
                                ForEach([4, 5, 6, 7, 8], id: \.self) { s in
                                    Text("\(s)×\(s)").tag(s)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        // Variant picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Variant")
                                .font(.subheadline.bold())
                                .foregroundStyle(.secondary)
                            Picker("Variant", selection: $game.variant) {
                                ForEach([GameVariant.faceUp, .faceDown, .blind], id: \.self) { v in
                                    Text(v.rawValue).tag(v)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        // Mode picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Mode")
                                .font(.subheadline.bold())
                                .foregroundStyle(.secondary)
                            Picker("Mode", selection: $game.mode) {
                                ForEach(GameMode.allCases) { m in
                                    Text(m.rawValue).tag(m)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        // Fast Game toggle
                        Toggle(isOn: $fastGame) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Fast Game")
                                    .font(.callout.bold())
                                Text("No AI suggestions, no delays")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .onChange(of: fastGame) { _, newValue in
                            game.fastGame = newValue
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
                                LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                            )
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(game.selectedTopics.isEmpty || isLoading)

                        if isLoading {
                            ProgressView("Loading questions...")
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

                    Spacer()
                }
            }
            .fullScreenCover(isPresented: $showGame) {
                GamePlayView(game: game, onExit: {
                    showGame = false
                    game.reset()
                })
            }
            .sheet(isPresented: $showHowToPlay) {
                HowToPlayView()
            }
            .sheet(isPresented: $showAbout) {
                AboutView()
            }
            .task {
                game.fastGame = fastGame
                gcManager.authenticate()
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
                            .background(isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                            .foregroundStyle(isSelected ? .blue : .secondary)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                            )
                        }
                    }
                }
            }
        }
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

    private func startGame() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let topicIds = game.selectedTopics.map(\.id)
                let questions = try await QrossAPI.fetchQuestions(categories: topicIds)
                let needed = game.boardSize * game.boardSize
                guard questions.count >= needed else {
                    errorMessage = "Not enough questions. Select more topics."
                    isLoading = false
                    return
                }
                game.startGame(questions: questions)
                isLoading = false
                showGame = true
            } catch {
                errorMessage = "Failed to load questions: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
}
