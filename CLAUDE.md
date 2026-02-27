# Qross — Grid Trivia Game for iOS

A beautiful standalone iOS trivia game where players navigate a colored grid from corner to corner by answering questions correctly. Each cell holds a trivia question from a topic. Strategy meets knowledge.

## Quick Start

```bash
cd ~/qross && xcodegen generate
open Qross.xcodeproj
# Or build from CLI:
xcodebuild -scheme Qross -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2' build
```

## Architecture

| Layer | What | Where |
|-------|------|-------|
| Question pool | Trivia decks (20+ categories, 9k+ questions) | card-engine API on Fly |
| Game logic | Board gen, adjacency, scoring, win/lose | On-device (Swift) |
| Game state | Current board, moves, score | On-device (SwiftData) |
| Leaderboards | Compare with friends, daily challenge | Game Center |
| Offline cache | Downloaded question packs per topic | Local JSON cache |

**card-engine is the question warehouse, not the game server.** App fetches questions at game start (or from cache), then all game logic runs locally.

## API Dependency

| Endpoint | Purpose |
|----------|---------|
| `GET /api/v1/trivia/gamedata` | Bulk trivia fetch (all categories) |
| `GET /api/v1/trivia/categories` | Category list with counts |

Base URL: `https://bd-card-engine.fly.dev`

## Targets

| Target | Type | Bundle ID |
|--------|------|-----------|
| Qross | iOS App | `com.billdonner.qross` |
| QrossClip | App Clip | `com.billdonner.qross.Clip` |

## Game Rules

### Board
- Square grid, 4×4 to 8×8 (UI picker offers 4, 5, 6, 7, 8)
- Each cell contains a trivia question from a topic
- Each topic has an assigned color; cells are colored by topic

### Pick Your Corner (Start/End)
All 4 corners are highlighted at game start. The player taps any corner to begin:
- Answering that corner correctly locks it as the **start**
- The diagonally opposite corner becomes the **goal**
- Example: pick top-right → goal is bottom-left

| Corner Picked | Goal |
|---------------|------|
| Top-left | Bottom-right (Classic ↘) |
| Top-right | Bottom-left (Reverse ↙) |
| Bottom-left | Top-right (Uphill ↗) |
| Bottom-right | Top-left (Downhill ↖) |

### Movement
- First move is always one of the 4 corners (player's choice)
- Each subsequent move must be adjacent (8-connected: orthogonal + diagonal) to the last **successful** cell
- Wrong answers do NOT advance position — cell is burned/blocked
- Available cells pulse to show they're tappable

### Hints
Two hint types are available during the question overlay:
- **Show Hint (+1)**: Reveals the challenge's hint text (if available). Adds 1 to `hintPenalty`.
- **Eliminate (+2)**: Removes one wrong answer choice. Adds 2 to `hintPenalty`.

### Win/Lose
- **Win**: answer the end cell correctly
- **Lose**: accumulate N wrong answers (varies by board size), OR run out of reachable cells
- **Score**: `moves + (wrong × 2) + hintPenalty` — lower is better

### Wrong Answer Tolerance by Board Size
| Board | Max Wrong |
|-------|-----------|
| 4×4 | 2 |
| 5×5 | 3 |
| 6×6 | 4 |
| 7×7 | 5 |
| 8×8 | 6 |

## Game Variants

| Variant | Description |
|---------|-------------|
| **Face Up** | All questions visible — pure strategy mode |
| **Face Down** | Only topic colors shown — questions revealed on tap |
| **Blind** | No colors, no questions — full fog of war |
| **Concentration** | Even-sized boards only (4×4, 6×6, 8×8). Questions duplicated in two random cells, must match both before answering. Both cells marked correct/incorrect together |

## Difficulty Knobs

| Knob | Easy | Hard |
|------|------|------|
| Board size | 4×4 | 8×8+ |
| Wrong answers allowed | 5+ | 2 |
| Question difficulty | Easy only | Mixed/hard |
| Variant | Face up | Blind |
| Topics | Player picks all | Game forces some |
| Timer | None | 15 seconds |

## Daily Challenge

Same seeded board for all players each day (same topics, questions, layout). Leaderboard via Game Center. Shareable results grid:

```
Qross Daily 5×5 — 7 moves, 1 miss
🟩🟩⬜⬜⬜
⬜🟩⬜⬜⬜
⬜🟩🟩⬜⬜
⬜⬜🟩🟩⬜
⬜⬜⬜🟩🟩
```

## App Clip

The App Clip (`QrossClip`) provides a single-game experience:
- Launched from a shared daily challenge link or QR code
- Pre-selected topics, 5×5 board, Face Down variant
- Shows score at end with "Get the full app" CTA
- No login, no onboarding — straight to gameplay
- Shares code with main app via shared Swift package/framework

## Screen Flow

```
Launch
  └─ Onboarding (5-page TabView, first launch only)
       └─ Home (animated grid background)
            ├─ Board Size picker (4-8 segmented)
            ├─ Variant picker (Face Up / Face Down / Blind)
            ├─ Topic picker (horizontal capsule pills)
            ├─ Play → GamePlayView (full-screen cover)
            │    ├─ Pick corner (all 4 highlighted)
            │    ├─ Answer question → correct/wrong
            │    │    ├─ Hint: Show Hint (+1) / Eliminate (+2)
            │    ├─ Win → score card + share
            │    └─ Lose → reason + score card
            ├─ Leaderboards (Game Center, if authenticated)
            └─ Stats (StatsView)
```

## Project Structure

```
qross/
├── project.yml              # xcodegen spec
├── CLAUDE.md                # This file
├── Docs/
│   ├── game-design.md       # Full game design document
│   └── user-manual.md       # Player-facing user manual
├── Qross/                   # Main app target
│   ├── App/
│   │   └── QrossApp.swift        # @main, RootView with onboarding gate
│   ├── Models/
│   │   ├── Board.swift            # Grid, cells, corners, adjacency
│   │   ├── GameState.swift        # Game state machine, corner-pick, hints
│   │   ├── Topic.swift            # Topic model + color palette
│   │   ├── Challenge.swift        # Question/answer/hint model
│   │   └── Score.swift            # GameScore struct + ratings
│   ├── Views/
│   │   ├── OnboardingView.swift   # 5-page first-launch onboarding
│   │   ├── HomeView.swift         # Main menu with size/variant/topic pickers
│   │   ├── GamePlayView.swift     # Full-screen game container + result overlay
│   │   ├── BoardView.swift        # The main game grid
│   │   ├── CellView.swift         # Individual cell rendering
│   │   ├── QuestionOverlay.swift  # Question popup with hints
│   │   └── StatsView.swift        # Game statistics
│   ├── Services/
│   │   ├── APIClient.swift        # card-engine API
│   │   ├── QuestionCache.swift    # Offline question storage
│   │   └── GameCenterManager.swift
│   ├── Assets.xcassets/
│   └── Info.plist
├── QrossClip/               # App Clip target
│   ├── QrossClipApp.swift
│   ├── ClipContentView.swift
│   ├── Assets.xcassets/
│   └── Info.plist
└── QrossTests/
    ├── BoardTests.swift
    └── GameStateTests.swift
```

## Design Language

- **Grid cells**: Rounded squares with topic color, subtle shadow
- **Path**: Glowing connected line between successful cells
- **Correct**: Green flash, confetti particles, success haptic
- **Wrong**: Red shake, crack animation, thud haptic
- **Available cells**: Gentle pulse animation
- **Unavailable cells**: Dimmed
- **Typography**: SF Rounded for a friendly game feel
- **Dark mode**: First-class support, colors designed for both modes

## Ecosystem

| Repo | Path | Purpose |
|------|------|---------|
| **qross** | `~/qross` | This repo — iOS game |
| **card-engine** | `~/card-engine` | Trivia question API backend |
| **obo** | `~/obo` | Hub docs (game design originated here) |

## Build & Install

```bash
cd ~/qross && xcodegen generate
swift build -c release  # if CLI tools added later
```

## Ports

No local server needed — connects to card-engine on Fly.io.
