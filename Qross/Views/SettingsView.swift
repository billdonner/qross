import SwiftUI

struct SettingsView: View {
    @Bindable var game: GameState
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

    private var variantDescription: String {
        switch game.variant {
        case .faceUp: return "See all questions — pure strategy"
        case .faceDown: return "Questions hidden until adjacent — plan ahead"
        case .blind: return "No colors, no preview — full fog of war"
        case .concentration: return "Match pairs before answering"
        }
    }
}
