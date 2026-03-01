import SwiftUI

struct QuestionOverlay: View {
    let challenge: Challenge
    let topicColor: Color
    let topicName: String
    let onAnswer: (Int) -> Void
    let onDismiss: () -> Void
    let onHintUsed: (Int) -> Void  // cost passed back to GameState
    let fastGame: Bool

    @State private var selectedIndex: Int?
    @State private var revealed = false
    @State private var waitingForContinue = false
    @State private var showHintText = false
    @State private var eliminatedIndices: Set<Int> = []
    @State private var reported = false

    /// Whether the player's selected answer is correct
    private var isCorrectAnswer: Bool {
        guard let idx = selectedIndex else { return false }
        return challenge.choices[idx].isCorrect
    }

    /// Whether a hint-text hint is available (card has hint and not yet shown)
    private var canShowHint: Bool {
        challenge.hint != nil && !showHintText && !revealed
    }

    /// Whether we can eliminate a wrong choice (need 2+ wrong choices remaining)
    private var canEliminate: Bool {
        guard !revealed else { return false }
        let wrongIndices = challenge.choices.indices.filter {
            !challenge.choices[$0].isCorrect && !eliminatedIndices.contains($0)
        }
        return wrongIndices.count >= 2  // keep at least 1 wrong visible
    }

    var body: some View {
        VStack(spacing: 0) {
            // Topic badge + difficulty
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
                .padding(.bottom, 20)

            // Hint buttons (before answer)
            if !revealed {
                hintButtons
                    .padding(.bottom, 16)
            }

            // Shown hint text
            if showHintText, let hint = challenge.hint {
                HStack(spacing: 6) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.yellow)
                    Text(hint)
                        .italic()
                }
                .font(.callout)
                .padding(10)
                .frame(maxWidth: .infinity)
                .background(Color.yellow.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.bottom, 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Choices
            VStack(spacing: 10) {
                ForEach(Array(challenge.choices.enumerated()), id: \.offset) { index, choice in
                    if !eliminatedIndices.contains(index) {
                        Button {
                            guard !revealed else { return }
                            selectedIndex = index
                            revealed = true
                            let correct = challenge.choices[index].isCorrect
                            if correct {
                                // Correct: always auto-dismiss at 0.8s
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                    onAnswer(index)
                                }
                            } else if fastGame {
                                // Fast Game ON + wrong: auto-dismiss after 2s
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                    onAnswer(index)
                                }
                            } else {
                                // Fast Game OFF + wrong: wait for Continue button
                                waitingForContinue = true
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
                                } else if revealed && choice.isCorrect && !isCorrectAnswer {
                                    // Show checkmark on correct answer when player got it wrong
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                }
                            }
                            .padding(12)
                            .background(choiceBackground(index, choice: choice))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(revealed)
                        .transition(.asymmetric(
                            insertion: .identity,
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                    }
                }
            }
            .animation(.spring(duration: 0.3), value: eliminatedIndices)

            // Explanation (after reveal)
            if revealed, let explanation = challenge.explanation {
                Text(explanation)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 16)
                    .transition(.opacity)
            }

            // Report question (after reveal)
            if revealed {
                reportButton
                    .padding(.top, 12)
                    .transition(.opacity)
            }

            // Continue button (Fast Game OFF + wrong answer)
            if waitingForContinue {
                Button {
                    if let idx = selectedIndex {
                        onAnswer(idx)
                    }
                } label: {
                    Text("Continue")
                        .font(.callout.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.top, 16)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 20)
        .padding(20)
    }

    // MARK: - Hint Buttons

    private var hintButtons: some View {
        HStack(spacing: 12) {
            // Show Hint button — always visible, disabled when no hint
            Button {
                showHintText = true
                onHintUsed(1)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "lightbulb.fill")
                    Text("Show Hint")
                    Text("+1")
                        .fontWeight(.heavy)
                }
                .font(.callout.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(canShowHint ? Color.yellow.opacity(0.2) : Color.gray.opacity(0.1))
                .foregroundStyle(canShowHint ? .primary : .quaternary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!canShowHint)

            // Eliminate button — always visible, disabled when can't eliminate
            Button {
                eliminateOneWrong()
                onHintUsed(2)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "minus.circle.fill")
                    Text("Eliminate")
                    Text("+2")
                        .fontWeight(.heavy)
                }
                .font(.callout.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(canEliminate ? Color.red.opacity(0.15) : Color.gray.opacity(0.1))
                .foregroundStyle(canEliminate ? .primary : .quaternary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!canEliminate)
        }
    }

    // MARK: - Report

    private var reportButton: some View {
        HStack(spacing: 8) {
            Button {
                reported = true
                QrossAPI.reportQuestion(
                    challengeId: challenge.id.uuidString,
                    topic: topicName,
                    question: challenge.question,
                    reason: "inaccurate"
                )
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: reported ? "checkmark.circle.fill" : "flag")
                    Text(reported ? "Reported" : "Report Question")
                }
                .font(.caption)
                .foregroundStyle(reported ? .green : .secondary)
            }
            .disabled(reported)

            if reported, let mailto = reportMailtoURL {
                Link(destination: mailto) {
                    HStack(spacing: 4) {
                        Image(systemName: "envelope")
                        Text("Email Details")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var reportMailtoURL: URL? {
        let subject = "Qross: Question Report"
        let body = "Question: \(challenge.question)\nTopic: \(topicName)\nChallenge ID: \(challenge.id.uuidString)\n\nPlease describe the issue:\n"
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = "support@qross.app"
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body),
        ]
        return components.url
    }

    // MARK: - Eliminate

    private func eliminateOneWrong() {
        let wrongIndices = challenge.choices.indices.filter {
            !challenge.choices[$0].isCorrect && !eliminatedIndices.contains($0)
        }
        if let victim = wrongIndices.randomElement() {
            eliminatedIndices.insert(victim)
        }
    }

    // MARK: - Helpers

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
            return Color.green.opacity(0.2)
        }
        return Color(.systemBackground).opacity(0.4)
    }
}
