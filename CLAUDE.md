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
- Square grid, 4×4 to 10×10
- Each cell contains a trivia question from a topic
- Each topic has an assigned color; cells are colored by topic

### Start/End Positions
- **Default**: top-left corner → bottom-right corner
- **Reverse diagonal**: top-right → bottom-left
- **Random corners**: game picks two opposite-ish corners
- **Player choice**: tap any edge/corner cell to start, opposite edge/corner is the goal
- First and last cells must be answered correctly (special rules apply)

### Movement
- First move is always the start cell
- Each subsequent move must be adjacent (8-connected: orthogonal + diagonal) to the last **successful** cell
- Wrong answers do NOT advance position — cell is burned/blocked
- Available cells pulse to show they're tappable

### Win/Lose
- **Win**: answer the end cell correctly
- **Lose**: accumulate N wrong answers (varies by board size), OR run out of reachable cells
- **Score**: successful_moves + (wrong_answers × 2) — lower is better

### Wrong Answer Tolerance by Board Size
| Board | Max Wrong |
|-------|-----------|
| 4×4 | 2 |
| 5×5 | 3 |
| 6×6 | 4 |
| 7×7 | 5 |
| 8×8–10×10 | 6 |

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
  └─ Home (animated grid background)
       ├─ Daily Challenge (one tap to play today's board)
       ├─ New Game
       │    ├─ Pick Start/End (corner selector)
       │    ├─ Pick Topics (colorful pills, 1-26)
       │    ├─ Pick Board Size (visual preview)
       │    ├─ Pick Variant
       │    └─ GO → Game Board
       │         ├─ Tap cell → Question overlay (anchored to cell)
       │         │    ├─ Correct → glow, path extends, haptic
       │         │    └─ Wrong → crack, shake, life lost
       │         ├─ Win → celebration + score + share card
       │         └─ Lose → reveal optimal path
       ├─ Leaderboards (Game Center)
       ├─ Stats (games played, win %, best per size)
       ├─ Settings (difficulty, sound, haptics)
       └─ How to Play (animated tutorial)
```

## Project Structure

```
qross/
├── project.yml              # xcodegen spec
├── CLAUDE.md                # This file
├── Docs/
│   └── game-design.md       # Full game design document
├── Qross/                   # Main app target
│   ├── App/
│   │   ├── QrossApp.swift
│   │   └── ContentView.swift
│   ├── Models/
│   │   ├── Board.swift       # Grid, cells, adjacency
│   │   ├── GameState.swift   # Current game state machine
│   │   ├── Topic.swift       # Topic model + colors
│   │   ├── Challenge.swift   # Question/answer model
│   │   └── Score.swift       # Scoring logic
│   ├── Views/
│   │   ├── HomeView.swift
│   │   ├── TopicPickerView.swift
│   │   ├── BoardView.swift        # The main game grid
│   │   ├── CellView.swift         # Individual cell rendering
│   │   ├── QuestionOverlay.swift  # Question popup anchored to cell
│   │   ├── ScoreView.swift        # End-of-game results
│   │   └── StatsView.swift
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
