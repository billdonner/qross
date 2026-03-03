import SwiftUI

/// App Clip: immediate 5×5 game with pre-selected topics
struct ClipContentView: View {
    @Bindable var game: GameState
    @State private var isLoading = true
    @State private var errorMessage: String?
    @AppStorage("qross_device_id") private var deviceId = ""
    @AppStorage("qross_player_id") private var playerId = ""

    private var topicColors: [String: Color] {
        let colored = TopicPalette.assign(to: game.selectedTopics)
        return Dictionary(uniqueKeysWithValues: colored.map { ($0.id, $0.color) })
    }

    var body: some View {
        ZStack {
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Loading Qross...")
                        .font(.headline)
                }
            } else if let error = errorMessage {
                VStack(spacing: 16) {
                    Text("⚠️")
                        .font(.largeTitle)
                    Text(error)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Button("Retry") { Task { await loadAndStart() } }
                }
            } else {
                switch game.phase {
                case .playing:
                    BoardView(game: game, topicColors: topicColors)
                case .won, .lostWrong, .lostStuck:
                    clipResultView
                default:
                    ProgressView()
                }
            }
        }
        .task { await loadAndStart() }
    }

    private var clipResultView: some View {
        VStack(spacing: 20) {
            Text(game.phase == .won ? "🎉 You Won!" : "💥 Game Over")
                .font(.title.bold())

            Text("Score: \(game.score)")
                .font(.title2)

            if game.phase == .won {
                ShareLink(item: game.shareText()) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }

            VStack(spacing: 8) {
                Text("Want more?")
                    .font(.headline)
                Text("Get Qross for daily challenges, custom topics, and leaderboards.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Link("Get Qross", destination: URL(string: "https://apps.apple.com/app/qross/id0000000000")!)
                    .font(.callout.bold())
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            .padding(.top, 20)
        }
        .padding()
    }

    private func loadAndStart() async {
        isLoading = true

        // Register player for deduplication
        if deviceId.isEmpty { deviceId = UUID().uuidString }
        if playerId.isEmpty {
            if let pid = try? await QrossAPI.registerPlayer(deviceId: deviceId) {
                playerId = pid
            }
        }

        do {
            let allTopics = try await QrossAPI.fetchCategories()
            // Pick 3 popular topics for the clip
            let popular = allTopics
                .filter { $0.questionCount >= 100 }
                .prefix(3)
            game.selectedTopics = Array(popular)
            game.boardSize = 5
            game.cornerPair = .topLeftToBottomRight
            game.variant = .faceDown

            let pid = playerId.isEmpty ? nil : playerId
            let result = try await QrossAPI.fetchQuestions(
                categories: game.selectedTopics.map(\.id),
                playerId: pid
            )
            game.shareCode = result.shareCode
            game.startGame(questions: result.challenges)
            isLoading = false
        } catch {
            errorMessage = "Could not load. Check your connection."
            isLoading = false
        }
    }
}
