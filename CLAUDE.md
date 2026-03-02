# Qross — Grid Trivia Game for iOS

A beautiful standalone iOS trivia game where players navigate a colored grid from corner to corner by answering questions correctly. Each cell holds a trivia question from a topic. Strategy meets knowledge.

## Stack
- SwiftUI, iOS 26+ (@Observable, no MVVM — views own state directly)
- Swift 5.9, Xcode 26+
- No SPM dependencies — pure Apple frameworks
- Project generated with xcodegen from `project.yml`
- Bundle ID: `com.qross.app`, Version: 0.2 (build 17)

## Common Commands
- `cd ~/qross && xcodegen generate` — regenerate Xcode project from project.yml
- `xcodebuild -scheme Qross -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2' build` — build
- `xcodebuild -scheme QrossTests -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2' test` — run tests (20 as of 2026-03-02)
- `open Qross.xcodeproj` — open in Xcode

## Cross-Project Sync
After any API change in cardzerver that affects `/api/v1/trivia/gamedata` or `/api/v1/trivia/categories`:
- Update `QrossAPI` response models in `Qross/Services/APIClient.swift`
- Update `Challenge` model in `Qross/Models/Challenge.swift` if response shape changes
- **Run `xcodegen generate` after adding or removing any Swift file**

## Version Management

Qross uses a simple versioning scheme — no client/server API version negotiation (the API is read-only trivia data).

### Where versions live

| What | File | Field |
|------|------|-------|
| Marketing version | `project.yml` | `MARKETING_VERSION` |
| Build number | `project.yml` | `CURRENT_PROJECT_VERSION` |
| Backup (main app) | `Qross/Info.plist` | `CFBundleShortVersionString`, `CFBundleVersion` |
| Backup (clip) | `QrossClip/Info.plist` | `CFBundleShortVersionString`, `CFBundleVersion` |

### When to bump

| Change type | What to bump |
|-------------|-------------|
| Any TestFlight build | `CURRENT_PROJECT_VERSION` (+1) in project.yml, both Info.plists, then `xcodegen generate` |
| App Store release | `MARKETING_VERSION` (semver) + reset build to 1 |

**Keep all three files in sync** — project.yml is the source of truth but Info.plists must match for App Clip consistency.

## Architecture

| Layer | What | Where |
|-------|------|-------|
| Question pool | Trivia decks (20+ categories, 9k+ questions) | cardzerver API on Fly |
| Game logic | Board gen, adjacency, scoring, win/lose | On-device (Swift) |
| Game state | Current board, moves, score | On-device (@Observable) |
| Leaderboards | Compare with friends, daily challenge | Game Center |
| Offline cache | Downloaded question packs per topic | Local JSON cache |

**cardzerver is the question warehouse, not the game server.** App fetches questions at game start (or from cache), then all game logic runs locally.

- `GameState` is `@Observable` — single source of truth for board, phase, score, path
- `QrossAPI` is a static struct (stateless HTTP calls), not an actor
- `QuestionCache` is an actor (thread-safe disk I/O for offline question storage)
- `GameCenterManager` is `@Observable` — drives leaderboard UI based on auth state
- `TopicPalette.assign()` dynamically assigns colors at game start — colors are not persisted or sent over the wire
- `Board` is a value type (struct) — immutable after generation, mutated via copy-on-write in GameState
- `MoveAdvisor` uses Apple FoundationModels (on-device LLM) — runtime `isAvailable` check for devices without Apple Intelligence; falls back to deterministic suggestions

## AI Features

All AI features use Apple FoundationModels (on-device LLM). Every feature has a deterministic fallback for devices without Apple Intelligence. All gated by `QrossAI.isAvailable` / `MoveAdvisor.isAvailable` runtime check. Disabled entirely in Fast Game mode.

### Move Suggestions (`MoveAdvisor.swift`)
- **Pathfinding:** `Board.shortestPath(from:to:)` — BFS on 8-connected grid, instant, always optimal
- **AI explanation:** `MoveAdvisor.explainMove()` — `@Generable MoveExplanation` generates a reason for the BFS-chosen cell
- **Fallback:** "Topic (difficulty) — N steps to goal"
- **UI:** Purple banner + solid purple border on suggested cell + dashed border on path to goal
- Triggers on `game.currentPosition` change, cancels previous Task on rapid moves

### Board Preview (`QrossAI.previewBoard`)
- One-sentence board assessment shown during corner-picking phase
- Uses eye icon in purple banner: "This board is heavy on Science — expect a challenge!"
- **Fallback:** "This board is heavy on [dominant topic] — pick your corner wisely!"

### Hint Generation (`QrossAI.generateHint`)
- When a question has no built-in hint, AI generates one on demand
- Triggered by "Show Hint" button tap — shows loading spinner, then hint
- **Fallback:** Button disabled (no hint available)

### Explanation Generation (`QrossAI.generateExplanation`)
- When a question has no built-in explanation, AI generates one after answer reveal
- Shows loading spinner below answer choices, then explanation text
- Only in non-fast mode (answer review screen has 10s timeout)
- **Fallback:** No explanation shown

### Post-Game Analysis (`QrossAI.analyzeGame`)
- One-sentence performance analysis shown in result overlay after game ends
- Computes per-topic correct/wrong counts, feeds to AI
- **Fallback:** Deterministic analysis: "Strong in [best topic]! Work on [worst topic]."

### Difficulty Estimation (`Challenge.estimateDifficulty`)
- Heuristic-based (no AI, instant) — runs at question parse time in `APIClient`
- Factors: question length, answer text length, shared words across answers, negation words
- Replaces hardcoded `.medium` — difficulty badges now reflect actual question characteristics

## API Dependency

| Endpoint | Purpose |
|----------|---------|
| `GET /api/v1/trivia/gamedata` | Bulk trivia fetch (all categories) |
| `GET /api/v1/trivia/categories` | Category list with counts |

Base URL: `https://bd-cardzerver.fly.dev`

## Targets

| Target | Type | Bundle ID |
|--------|------|-----------|
| Qross | iOS App | `com.qross.app` |
| QrossClip | App Clip | `com.qross.app.Clip` |

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
| 4×4 | 4 |
| 5×5 | 10 |
| 6×6 | 10 |
| 7×7 | 10 |
| 8×8 | 10 |

## Game Modes

Mode controls the **win condition structure** (how many legs to complete). Separate from variant (which controls visibility).

| Mode | Description |
|------|-------------|
| **Single** | One diagonal — navigate from start corner to opposite corner (default) |
| **Double Cross** | Two legs — complete the first diagonal, then continue to one of the two remaining corners. Board state carries over (correct cells traversable, burned cells stay blocked, lives accumulate). Min score = `2 × board_size` |

### Double Cross Flow
1. Pick a corner → navigate to opposite corner (Leg 1)
2. Two remaining corners pulse → pick your next target
3. Navigate from Leg 1 endpoint to chosen corner (Leg 2)
4. Answer the final corner correctly → Win

## Game Variants

| Variant | Description |
|---------|-------------|
| **Face Up** | All questions visible — pure strategy mode |
| **Face Down** | Only topic colors shown — questions revealed on tap |
| **Blind** | No colors, no questions — full fog of war |
| **Concentration** | *(Planned, not yet in UI)* Even-sized boards only (4×4, 6×6, 8×8). Questions duplicated in two random cells, must match both before answering. Both cells marked correct/incorrect together |

## Difficulty Knobs

| Knob | Easy | Hard |
|------|------|------|
| Board size | 4×4 | 8×8+ |
| Wrong answers allowed | 5+ | 2 |
| Question difficulty | Easy only | Mixed/hard |
| Variant | Face up | Blind |
| Topics | Player picks all | Game forces some |
| Timer | None | 15 seconds |

## Daily Challenge *(Planned)*

Same seeded board for all players each day (same topics, questions, layout). Leaderboard via Game Center. Shareable results grid. Seed generation is not yet implemented — infrastructure exists (SeededRNG, CornerPair, share text) but the date-based seed is a TODO.

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
            │    ├─ Win → confetti + score card + share
            │    └─ Lose → reason + score card + share
            ├─ How to Play (HowToPlayView, sheet)
            ├─ About (AboutView, sheet)
            └─ Leaderboards (Game Center, if authenticated)
```

## Project Structure

```
qross/
├── project.yml              # xcodegen spec
├── CLAUDE.md                # This file
├── README.md                # Public-facing project intro
├── Docs/
│   ├── game-design.md       # Full game design document
│   ├── user-manual.md       # Player-facing user manual
│   ├── appstore-copy.md     # App Store Connect metadata
│   └── testflight-notes-build4.md  # Latest TestFlight release notes
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
│   │   ├── CellView.swift         # Individual cell rendering (bounce/shake animations)
│   │   ├── QuestionOverlay.swift  # Question popup with hints
│   │   ├── ConfettiView.swift     # Canvas particle burst on win
│   │   ├── StatsView.swift        # Game statistics + history
│   │   ├── HowToPlayView.swift    # Rules & strategy guide
│   │   └── AboutView.swift        # About screen with feature list
│   ├── Services/
│   │   ├── APIClient.swift        # cardzerver API
│   │   ├── QuestionCache.swift    # Offline question storage
│   │   ├── GameCenterManager.swift
│   │   ├── HapticEngine.swift     # Centralized haptic feedback (6 feedback types)
│   │   ├── MoveAdvisor.swift      # BFS pathfinding + AI move explanations
│   │   └── QrossAI.swift          # AI hints, explanations, analysis, board preview
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
- **Correct**: Green flash + scale bounce (1.15x), success haptic
- **Wrong**: Red shake (±6pt horizontal), error haptic
- **Win**: Confetti particle burst (80 particles, Canvas, 3s), double success haptic
- **Haptics**: Centralized via `HapticEngine` — toggle in HomeView settings (`@AppStorage("enableHaptics")`)
- **Available cells**: Gentle pulse animation
- **Unavailable cells**: Dimmed
- **Typography**: SF Rounded for a friendly game feel
- **Dark mode**: First-class support, colors designed for both modes

## Ecosystem

| Repo | Path | Purpose |
|------|------|---------|
| **qross** | `~/qross` | This repo — iOS game |
| **cardzerver** | `~/cardzerver` | Trivia question API backend |
| **obo** | `~/obo` | Hub docs (game design originated here) |

## Build & Install

```bash
cd ~/qross && xcodegen generate
swift build -c release  # if CLI tools added later
```

## Known Issues & Fixes
- App Clip store link is placeholder (`id0000000000`) — replace with real App Store ID after first approval
- Daily challenge seed is `nil` (TODO in GameState.swift:65) — date-based seed generation not yet implemented
- StatsView shows game history from `GameHistory` actor (UserDefaults-backed)
- Concentration variant enum exists but is hidden from UI picker — gameplay logic for pair-matching not implemented
- Difficulty uses `ai_difficulty` from API when available (client trims double-quoted values from DB bug); falls back to heuristic `Challenge.estimateDifficulty`
- Game Center entitlement not yet added — needs provisioning profile with Game Center capability enabled in Apple Developer portal first
- `xcodegen generate` reverts `Qross/Qross.entitlements` and `QrossClip/QrossClip.entitlements` to empty — must rewrite after running xcodegen if entitlements are needed

## Ports

No local server needed — connects to cardzerver on Fly.io.
