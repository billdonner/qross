import SwiftUI

struct HowToPlayView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    section("The Grid") {
                        Text("The board is a square grid of colored cells. Each cell holds a trivia question from a topic, and each topic has its own color.")
                        Text("Board sizes range from 4\u{00d7}4 (16 cells) to 8\u{00d7}8 (64 cells).")
                    }

                    section("Pick Your Corner") {
                        Text("When the board appears, all **4 corners** glow. Tap the corner where you want to start.")
                        Text("Answer correctly to lock it in. The diagonally **opposite** corner becomes your goal.")
                        cornerTable
                    }

                    section("Movement") {
                        Text("Move to any of the **8 cells** surrounding your position (up, down, left, right, and diagonals).")
                        bulletList([
                            "Correct answers extend your path",
                            "Wrong answers burn the cell permanently",
                            "Your position stays put after a wrong answer",
                        ])
                    }

                    section("Hints") {
                        HStack(spacing: 12) {
                            hintBadge("lightbulb", "Show Hint", "+1", .yellow)
                            hintBadge("minus.circle", "Eliminate", "+2", .red)
                        }
                        Text("Show Hint reveals a text clue. Eliminate removes one wrong answer. Both add to your score.")
                    }

                    section("Scoring") {
                        HStack {
                            Spacer()
                            Text("moves + (wrong \u{00d7} 2) + hints")
                                .font(.system(.body, design: .monospaced))
                                .padding(12)
                                .background(Color.purple.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            Spacer()
                        }
                        Text("Lower is better. Minimum possible = board size (a perfect diagonal with no mistakes).")
                        ratingTable
                    }

                    section("Variants") {
                        variantRow("Face Up", "eye", "All questions visible — plan your route", .blue)
                        variantRow("Face Down", "eye.slash", "Only topic colors shown", .purple)
                        variantRow("Blind", "eye.slash.circle", "No colors, no questions — fog of war", .gray)
                    }

                    section("Wrong Answer Limits") {
                        wrongTable
                    }

                    section("Tips") {
                        bulletList([
                            "Survey the board before picking a corner",
                            "Favor diagonal moves — they cover the most ground",
                            "Avoid dead ends — check a cell has onward neighbors",
                            "A +1 hint is cheaper than burning a critical cell",
                            "Start with 4\u{00d7}4 boards to learn the mechanics",
                        ])
                    }
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("How to Play")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Helpers

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3.bold())
            content()
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func bulletList(_ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Text("\u{2022}")
                    Text(item)
                }
            }
        }
    }

    private func hintBadge(_ icon: String, _ label: String, _ cost: String, _ color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(label)
                .font(.caption.bold())
            Text(cost)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func variantRow(_ name: String, _ icon: String, _ desc: String, _ color: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.subheadline.bold())
                Text(desc).font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private var cornerTable: some View {
        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
            GridRow {
                Text("You Pick").font(.caption.bold())
                Text("Your Goal").font(.caption.bold())
            }
            Divider()
            GridRow { Text("Top-left"); Text("Bottom-right \u{2198}") }
            GridRow { Text("Top-right"); Text("Bottom-left \u{2199}") }
            GridRow { Text("Bottom-left"); Text("Top-right \u{2197}") }
            GridRow { Text("Bottom-right"); Text("Top-left \u{2196}") }
        }
        .font(.subheadline)
    }

    private var ratingTable: some View {
        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 6) {
            GridRow {
                Text("Rating").font(.caption.bold())
                Text("Condition").font(.caption.bold())
            }
            Divider()
            GridRow { Text("\u{1f31f} Perfect"); Text("= minimum") }
            GridRow { Text("\u{2b50} Excellent"); Text("+1\u{2013}2") }
            GridRow { Text("\u{1f44d} Good"); Text("+3\u{2013}5") }
            GridRow { Text("\u{2705} Completed"); Text("above Good") }
        }
        .font(.subheadline)
    }

    private var wrongTable: some View {
        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 6) {
            GridRow {
                Text("Board").font(.caption.bold())
                Text("Max Wrong").font(.caption.bold())
            }
            Divider()
            GridRow { Text("4\u{00d7}4"); Text("4") }
            GridRow { Text("5\u{00d7}5"); Text("10") }
            GridRow { Text("6\u{00d7}6"); Text("10") }
            GridRow { Text("7\u{00d7}7"); Text("10") }
            GridRow { Text("8\u{00d7}8"); Text("10") }
        }
        .font(.subheadline)
    }
}
