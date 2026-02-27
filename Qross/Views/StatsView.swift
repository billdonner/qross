import SwiftUI

struct StatsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Stats")
                .font(.title2.bold())
            Text("Coming soon — game history, win rates, and streaks.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
