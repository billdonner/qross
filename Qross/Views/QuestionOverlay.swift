import SwiftUI

struct QuestionOverlay: View {
    let challenge: Challenge
    let topicColor: Color
    let topicName: String
    let onAnswer: (Int) -> Void
    let onDismiss: () -> Void

    @State private var selectedIndex: Int?
    @State private var revealed = false

    var body: some View {
        VStack(spacing: 0) {
            // Topic badge
            HStack {
                Text(topicName)
                    .font(.caption.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(topicColor.opacity(0.2))
                    .foregroundStyle(topicColor)
                    .clipShape(Capsule())

                Spacer()

                difficultyBadge
            }
            .padding(.bottom, 16)

            // Question
            Text(challenge.question)
                .font(.title3.bold())
                .multilineTextAlignment(.center)
                .padding(.bottom, 24)

            // Choices
            VStack(spacing: 12) {
                ForEach(Array(challenge.choices.enumerated()), id: \.offset) { index, choice in
                    Button {
                        guard !revealed else { return }
                        selectedIndex = index
                        revealed = true
                        // Brief delay before sending answer
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            onAnswer(index)
                        }
                    } label: {
                        HStack {
                            Text(choiceLetter(index))
                                .font(.callout.bold())
                                .frame(width: 28, height: 28)
                                .background(choiceLetterBG(index, choice: choice))
                                .foregroundStyle(.white)
                                .clipShape(Circle())

                            Text(choice.text)
                                .font(.body)
                                .multilineTextAlignment(.leading)

                            Spacer()

                            if revealed && index == selectedIndex {
                                Image(systemName: choice.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(choice.isCorrect ? .green : .red)
                            }
                        }
                        .padding(12)
                        .background(choiceBackground(index, choice: choice))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(revealed)
                }
            }

            // Explanation (after reveal)
            if revealed, let explanation = challenge.explanation {
                Text(explanation)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 16)
                    .transition(.opacity)
            }

            // Hint
            if !revealed, let hint = challenge.hint {
                HStack {
                    Image(systemName: "lightbulb")
                    Text(hint)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 12)
            }
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 20)
        .padding(20)
    }

    private var difficultyBadge: some View {
        Text(challenge.difficulty.rawValue.capitalized)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(difficultyColor.opacity(0.2))
            .foregroundStyle(difficultyColor)
            .clipShape(Capsule())
    }

    private var difficultyColor: Color {
        switch challenge.difficulty {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }

    private func choiceLetter(_ index: Int) -> String {
        ["A", "B", "C", "D"][index]
    }

    private func choiceLetterBG(_ index: Int, choice: Choice) -> Color {
        if revealed && index == selectedIndex {
            return choice.isCorrect ? .green : .red
        }
        return topicColor
    }

    private func choiceBackground(_ index: Int, choice: Choice) -> Color {
        if !revealed { return Color(.systemBackground).opacity(0.8) }
        if index == selectedIndex {
            return choice.isCorrect ? Color.green.opacity(0.15) : Color.red.opacity(0.15)
        }
        if choice.isCorrect {
            return Color.green.opacity(0.1)
        }
        return Color(.systemBackground).opacity(0.4)
    }
}
