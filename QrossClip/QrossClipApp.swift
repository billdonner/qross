import SwiftUI

@main
struct QrossClipApp: App {
    @State private var game = GameState()

    var body: some Scene {
        WindowGroup {
            ClipContentView(game: game)
        }
    }
}
