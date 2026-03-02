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
    @AppStorage("textSize") private var textSize = 1

    private var dynamicTypeSize: DynamicTypeSize {
        switch textSize {
        case 0: return .small
        case 2: return .xLarge
        case 3: return .xxLarge
        default: return .large
        }
    }

    var body: some View {
        Group {
            if hasSeenOnboarding {
                HomeView()
            } else {
                OnboardingView {
                    hasSeenOnboarding = true
                }
            }
        }
        .dynamicTypeSize(dynamicTypeSize)
    }
}
