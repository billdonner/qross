# Qross

SwiftUI iOS trivia game where players navigate a colored grid from corner to corner by answering questions correctly. Strategy meets knowledge.

## Stack

- SwiftUI, iOS 17+ (@Observable)
- Swift 5.9, Xcode 16+
- No external dependencies — pure Apple frameworks
- Xcode project generated with [XcodeGen](https://github.com/yonaskolb/XcodeGen) from `project.yml`
- Questions served by [cardzerver](https://github.com/billdonner/cardzerver) on Fly.io

## How It Works

Players navigate a square grid (4x4 to 8x8) from one corner to the diagonally opposite corner. Each cell holds a trivia question colored by topic. Correct answers advance your position; wrong answers burn the cell and cost a life.

| Feature | Detail |
|---------|--------|
| Board sizes | 4x4 through 8x8 |
| Variants | Face Up (see all), Face Down (colors only), Blind (fog of war) |
| Movement | 8-connected adjacency (orthogonal + diagonal) |
| Hints | Show Hint (+1 penalty), Eliminate (+2 penalty) |
| Scoring | `moves + (wrong x 2) + hintPenalty` — lower is better |
| Sharing | Emoji grid result card (like Wordle) |

## Architecture

| Layer | Key files |
|-------|-----------|
| Models | `Qross/Models/` — Board, GameState, Challenge, Topic, Score |
| Views | `Qross/Views/` — HomeView, BoardView, CellView, QuestionOverlay, GamePlayView |
| Services | `Qross/Services/` — QrossAPI (HTTP), QuestionCache (disk), GameCenterManager |
| App Clip | `QrossClip/` — Standalone 5x5 game with "Get the full app" CTA |
| Tests | `QrossTests/` — Board logic and game state flow |

## Getting Started

```bash
# Generate the Xcode project
cd ~/qross && xcodegen generate

# Open in Xcode
open Qross.xcodeproj
```

Build and run on an iOS 17+ simulator or device. No local server needed — connects to cardzerver on Fly.io.

## Tests (9)

```bash
xcodebuild -scheme QrossTests \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2' test
```

## Related Repos

| Repo | Description |
|------|-------------|
| [cardzerver](https://github.com/billdonner/cardzerver) | Unified trivia + flashcard API backend |
| [obo](https://github.com/billdonner/obo) | Hub docs and game design specs |
