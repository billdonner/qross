import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void
    @State private var currentPage = 0
    @ScaledMetric(relativeTo: .largeTitle) private var iconSize: CGFloat = 72
    @ScaledMetric(relativeTo: .title) private var titleSize: CGFloat = 28

    private let pages: [(icon: String, title: String, subtitle: String, color: Color)] = [
        ("square.grid.3x3.fill",
         "Welcome to Qross",
         "Navigate a colorful trivia grid from corner to corner. Strategy meets knowledge.",
         .blue),
        ("arrow.up.right.and.arrow.down.left.rectangle.fill",
         "Pick Your Corner",
         "All 4 corners are available at the start. Pick one — the opposite becomes your goal.",
         .purple),
        ("lightbulb.fill",
         "Answer & Use Hints",
         "Tap cells to answer questions. Use Show Hint (+1) or Eliminate (+2) when you need help.",
         .orange),
        ("star.fill",
         "Score & Compete",
         "Lower scores win. Share your emoji grid and compete on Game Center leaderboards.",
         .green),
        ("play.fill",
         "Ready to Qross?",
         "Choose your board size, pick your topics, and conquer the grid.",
         .pink),
    ]

    var body: some View {
        ZStack {
            // Background gradient matching current page
            pages[currentPage].color
                .opacity(0.15)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.4), value: currentPage)

            VStack(spacing: 0) {
                // Skip button (pages 1-4)
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button("Skip") {
                            onComplete()
                        }
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .padding(.trailing, 24)
                        .padding(.top, 16)
                    }
                }
                .frame(height: 44)

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        VStack(spacing: 24) {
                            Spacer()

                            Image(systemName: page.icon)
                                .font(.system(size: iconSize))
                                .foregroundStyle(page.color)
                                .symbolRenderingMode(.hierarchical)

                            Text(page.title)
                                .font(.system(size: titleSize, weight: .bold, design: .rounded))
                                .multilineTextAlignment(.center)

                            Text(page.subtitle)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)

                            Spacer()
                            Spacer()
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Custom page indicators
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage ? pages[currentPage].color : Color.gray.opacity(0.3))
                            .frame(width: index == currentPage ? 24 : 8, height: 8)
                            .animation(.spring(duration: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 24)

                // CTA button
                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        onComplete()
                    }
                } label: {
                    Text(currentPage < pages.count - 1 ? "Continue" : "Let's Play!")
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}
