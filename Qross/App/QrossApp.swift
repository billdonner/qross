import SwiftUI
import os

private let logger = Logger(subsystem: "com.qross.app", category: "DeepLink")

@main
struct QrossApp: App {
    /// Challenge code received via deep link, passed down to HomeView
    @State private var pendingChallengeCode: String?

    var body: some Scene {
        WindowGroup {
            RootView(pendingChallengeCode: $pendingChallengeCode)
                .onOpenURL { url in
                    logger.notice("onOpenURL: \(url.absoluteString)")
                    if let code = Self.extractChallengeCode(from: url) {
                        logger.notice("Challenge code: \(code)")
                        pendingChallengeCode = code.uppercased()
                    } else {
                        logger.warning("URL rejected: \(url.absoluteString)")
                    }
                }
        }
    }

    /// Extract 6-char challenge code from either:
    ///   - Universal Link: https://bd-cardzerver.fly.dev/challenge/ABCDEF
    ///   - Custom scheme:  qross://challenge/ABCDEF
    static func extractChallengeCode(from url: URL) -> String? {
        // Universal Link
        if url.scheme == "https",
           url.host == "bd-cardzerver.fly.dev",
           url.pathComponents.count >= 3,
           url.pathComponents[1] == "challenge" {
            let code = url.pathComponents[2]
            return code.count == 6 ? code : nil
        }
        // Custom scheme fallback
        if url.scheme == "qross",
           url.host == "challenge",
           let code = url.pathComponents.last,
           code.count == 6 {
            return code
        }
        return nil
    }
}

struct RootView: View {
    @Binding var pendingChallengeCode: String?
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
                HomeView(pendingChallengeCode: $pendingChallengeCode)
            } else {
                OnboardingView {
                    hasSeenOnboarding = true
                }
            }
        }
        .dynamicTypeSize(...dynamicTypeSize)
    }
}
