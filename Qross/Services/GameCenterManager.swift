import GameKit

@Observable
final class GameCenterManager {
    var isAuthenticated = false
    var playerName: String = ""

    func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            if let error {
                print("Game Center auth error: \(error.localizedDescription)")
                return
            }
            if viewController != nil {
                // Present the Game Center login view controller
                // This is handled automatically by iOS in most cases
                return
            }
            Task { @MainActor in
                self?.isAuthenticated = GKLocalPlayer.local.isAuthenticated
                self?.playerName = GKLocalPlayer.local.displayName
            }
        }
    }

    /// Submit score to a leaderboard
    func submitScore(_ score: Int, leaderboardID: String) async {
        guard isAuthenticated else { return }
        do {
            try await GKLeaderboard.submitScore(
                score,
                context: 0,
                player: GKLocalPlayer.local,
                leaderboardIDs: [leaderboardID]
            )
        } catch {
            print("Failed to submit score: \(error)")
        }
    }

    /// Show Game Center leaderboard
    func showLeaderboard() {
        guard isAuthenticated else { return }
        let vc = GKGameCenterViewController(state: .leaderboards)
        vc.gameCenterDelegate = GameCenterDismisser.shared
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(vc, animated: true)
        }
    }
}

/// Handles Game Center view controller dismissal
private class GameCenterDismisser: NSObject, GKGameCenterControllerDelegate {
    static let shared = GameCenterDismisser()
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
}
