import SwiftUI

struct SettingsView: View {
    @Bindable var game: GameState
    @Binding var availableTopics: [Topic]
    @AppStorage("fastGame") private var fastGame = false
    @AppStorage("enableHaptics") private var enableHaptics = true
    @AppStorage("textSize") private var textSize = 1
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Board") {
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
                        Text(variantDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

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
                }

                if !availableTopics.isEmpty {
                    Section("Topics") {
                        topicPicker
                    }
                }

                Section("Preferences") {
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

                    Toggle(isOn: $enableHaptics) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Haptics")
                                .font(.callout.bold())
                            Text("Vibrations on answers, wins, and taps")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Text Size")
                            .font(.subheadline.bold())
                            .foregroundStyle(.secondary)
                        Picker("Text Size", selection: $textSize) {
                            Text("Small").tag(0)
                            Text("Default").tag(1)
                            Text("Large").tag(2)
                            Text("XL").tag(3)
                        }
                        .pickerStyle(.segmented)
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
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

    private var variantDescription: String {
        switch game.variant {
        case .faceUp: return "See all questions — pure strategy"
        case .faceDown: return "Questions hidden until adjacent — plan ahead"
        case .blind: return "No colors, no preview — full fog of war"
        case .concentration: return "Match pairs before answering"
        }
    }
}
