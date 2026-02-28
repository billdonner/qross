# Qross — TestFlight Release Notes — Build 4 (0.2)

## What's New

**Corner Indicators Redesigned**
- Replaced small dot corner indicators with pulsing concentric rings during corner selection
- Goal corner now shows a star icon instead of an "E" text label
- Removed the "S" start label — the path and checkmark are sufficient

**Hint System Now Works**
- Hint text from the question database is now parsed and displayed when available
- Previously all hints were hardcoded to nil — "Show Hint" button was non-functional

**API URL Fixed**
- Corrected endpoint from retired bd-card-engine to bd-cardzerver
- Added `?tier=free` query parameter for category/question fetching

**Documentation Sync**
- All docs updated to match actual code (bundle IDs, API URLs, project structure)
- Concentration variant and Daily Challenge correctly marked as planned

## Under the Hood
- 9 unit tests passing (5 board logic, 4 game state flow)
- Debug print statements removed from GameCenterManager
- Info.plist versions synced across main app and App Clip

## What to Test

1. **Corner Selection**: Start a game — all 4 corners should pulse with concentric rings. Tap one, answer correctly, and verify the opposite corner shows a small star icon
2. **Hints**: During a question, tap "Show Hint" — if the question has hint text, it should appear below the question
3. **Topic Loading**: Home screen should load categories from the API and auto-select 3
4. **All Board Sizes**: Try 4x4, 5x5, and 8x8 — verify grid renders correctly
5. **Win/Lose**: Play through to a win and verify the share card generates correctly
6. **App Clip**: If testable, verify 5x5 Face Down game loads and plays through

## Known Issues
- App Clip store link is placeholder (id0000000000) — will be updated after App Store approval
- Daily Challenge not yet functional (seed generation is TODO)
- Stats screen is a placeholder
- Concentration variant is defined but not exposed in the variant picker

## Previous Builds
- Build 3: Fix API URL bd-card-engine to bd-cardzerver
- Build 2: Bump for TestFlight
- Build 1: Initial App Store prep (v0.2, bundle ID com.qross.app)
