import SwiftUI

@main
struct QrossApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

struct RootView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        if hasSeenOnboarding {
            HomeView()
        } else {
            OnboardingView {
                hasSeenOnboarding = true
            }
        }
    }
}
