import SwiftUI

struct QuestionOverlay: View {
    let challenge: Challenge
    let topicColor: Color
    let topicName: String
    let onAnswer: (Int) -> Void
    let onDismiss: () -> Void
    let onHintUsed: (Int) -> Void  // cost passed back to GameState
    let fastGame: Bool
    let currentHintPenalty: Int  // cumulative hint penalty so far this game

    @State private var selectedIndex: Int?
    @State private var revealed = false
    @State private var waitingForContinue = false
    @State private var showHintText = false
    @State private var eliminatedIndices: Set<Int> = []
    @State private var reported = false
    @State private var generatedHint: String?
    @State private var isGeneratingHint = false
    @State private var generatedExplanation: String?
    @State private var isGeneratingExplanation = false
    @State private var answered = false

    /// Whether the player's selected answer is correct
    private var isCorrectAnswer: Bool {
        guard let idx = selectedIndex else { return false }
        return idx == challenge.correctIndex
    }

    /// Whether a hint can be shown (always available — AI generates if no built-in hint)
    private var canShowHint: Bool {
        !showHintText && !revealed && !isGeneratingHint
    }

    /// Whether we can eliminate a wrong choice (need 2+ wrong choices remaining)
    private var canEliminate: Bool {
        guard !revealed else { return false }
        let wrongIndices = challenge.choices.indices.filter {
            $0 != challenge.correctIndex && !eliminatedIndices.contains($0)
        }
        return wrongIndices.count >= 2  // keep at least 1 wrong visible
    }

    var body: some View {
        ScrollView {
        VStack(spacing: 0) {
            // Topic badge + difficulty
            HStack {
                Text(topicName)
                    .font(.subheadline.bold())
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

            // Shown hint text (built-in or AI-generated)
            if showHintText {
                if let hint = challenge.hint ?? generatedHint {
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
                } else if isGeneratingHint {
                    HStack(spacing: 6) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Generating hint...")
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
            }

            // Choices
            VStack(spacing: 10) {
                ForEach(Array(challenge.choices.enumerated()), id: \.offset) { index, choice in
                    if !eliminatedIndices.contains(index) {
                        Button {
                            guard !revealed else { return }
                            selectedIndex = index
                            revealed = true
                            let correct = index == challenge.correctIndex
                            // Generate explanation if missing (non-fast mode)
                            if challenge.explanation == nil && !fastGame {
                                isGeneratingExplanation = true
                                Task {
                                    generatedExplanation = await QrossAI.generateExplanation(for: challenge)
                                    isGeneratingExplanation = false
                                }
                            }
                            if fastGame {
                                // Fast Game ON: auto-dismiss quickly
                                let delay = correct ? 0.8 : 2.0
                                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                                    guard !answered else { return }
                                    answered = true
                                    onAnswer(index)
                                }
                            } else {
                                // Fast Game OFF: show OK button, auto-dismiss after 10s
                                waitingForContinue = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                                    guard !answered else { return }
                                    answered = true
                                    waitingForContinue = false
                                    onAnswer(index)
                                }
                            }
                        } label: {
                            HStack {
                                Text(choiceLetter(index))
                                    .font(.callout.bold())
                                    .frame(width: 28, height: 28)
                                    .background(choiceLetterBG(index))
                                    .foregroundStyle(.white)
                                    .clipShape(Circle())

                                Text(choice.text)
                                    .font(.body)
                                    .multilineTextAlignment(.leading)

                                Spacer()

                                if revealed && index == selectedIndex {
                                    let isRight = index == challenge.correctIndex
                                    Image(systemName: isRight ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundStyle(isRight ? .green : .red)
                                } else if revealed && index == challenge.correctIndex && !isCorrectAnswer {
                                    // Show checkmark on correct answer when player got it wrong
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                }
                            }
                            .padding(12)
                            .background(choiceBackground(index))
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

            // Explanation (after reveal — built-in or AI-generated)
            if revealed {
                if let explanation = challenge.explanation ?? generatedExplanation {
                    Text(explanation)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.top, 16)
                        .transition(.opacity)
                } else if isGeneratingExplanation {
                    HStack(spacing: 6) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Generating explanation...")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 16)
                    .transition(.opacity)
                }
            }

            // Report question (after reveal)
            if revealed {
                reportButton
                    .padding(.top, 12)
                    .transition(.opacity)
            }

            // OK button (Fast Game OFF — dismiss after reviewing answer)
            if waitingForContinue {
                Button {
                    guard !answered else { return }
                    answered = true
                    waitingForContinue = false
                    if let idx = selectedIndex {
                        onAnswer(idx)
                    }
                } label: {
                    Text("OK")
                        .font(.callout.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(isCorrectAnswer ? Color.green : Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.top, 16)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(24)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 20)
        .padding(20)
    }

    // MARK: - Hint Buttons

    private var hintButtons: some View {
        VStack(spacing: 8) {
            if currentHintPenalty > 0 {
                Text("Hint penalty so far: \(currentHintPenalty) pts")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            HStack(spacing: 12) {
                // Show Hint button — AI generates if no built-in hint
                Button {
                    showHintText = true
                    onHintUsed(1)
                    if challenge.hint == nil {
                        isGeneratingHint = true
                        Task {
                            generatedHint = await QrossAI.generateHint(for: challenge)
                            isGeneratingHint = false
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "lightbulb.fill")
                        Text("Hint")
                        Text("(costs 1 pt)")
                            .fontWeight(.regular)
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
                        Text("(costs 2 pts)")
                            .fontWeight(.regular)
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
                .font(.subheadline)
                .foregroundStyle(reported ? .green : .secondary)
            }
            .disabled(reported)

            if reported, let mailto = reportMailtoURL {
                Link(destination: mailto) {
                    HStack(spacing: 4) {
                        Image(systemName: "envelope")
                        Text("Email Details")
                    }
                    .font(.subheadline)
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
            $0 != challenge.correctIndex && !eliminatedIndices.contains($0)
        }
        if let victim = wrongIndices.randomElement() {
            eliminatedIndices.insert(victim)
        }
    }

    // MARK: - Helpers

    private var difficultyBadge: some View {
        Text(challenge.difficulty.rawValue.capitalized)
            .font(.caption.bold())
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
        let letters = "ABCDEFGHIJ"
        guard index < letters.count else { return "\(index + 1)" }
        return String(letters[letters.index(letters.startIndex, offsetBy: index)])
    }

    private func choiceLetterBG(_ index: Int) -> Color {
        if revealed && index == selectedIndex {
            return index == challenge.correctIndex ? .green : .red
        }
        return topicColor
    }

    private func choiceBackground(_ index: Int) -> Color {
        if !revealed { return Color(.systemBackground).opacity(0.8) }
        if index == selectedIndex {
            return index == challenge.correctIndex ? Color.green.opacity(0.15) : Color.red.opacity(0.15)
        }
        if index == challenge.correctIndex {
            return Color.green.opacity(0.2)
        }
        return Color(.systemBackground).opacity(0.4)
    }
}
