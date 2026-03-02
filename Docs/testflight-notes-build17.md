# Qross — TestFlight Release Notes — Build 17 (0.2)

## What's New

**Offline Play**
- Questions are now cached locally after each game
- If the network is down, the game loads from cache automatically
- An orange "Offline mode" badge with wifi.slash icon appears when playing from cache
- First game requires a connection; after that you can play anywhere

**Text Size Control**
- New "Text Size" segmented picker on the home screen: Small, Default, Large, XL
- Persists across sessions

**Server-Side Category Filtering**
- The app now sends selected categories to the server instead of downloading all questions and filtering locally
- Faster load times, less bandwidth, especially on cellular

**AI Voice Fix**
- Post-game analysis, board previews, and all other AI-generated text now address you as "you" instead of referring to "the player" in third person

**Balanced Boards**
- Fixed round-robin topic allocation so each topic gets an equal number of cells
- Previously one topic could dominate the board depending on shuffle order

## Under the Hood
- Removed `isCorrect` field from `Choice` — correctness is now determined solely by `correctIndex`, eliminating a data redundancy that could cause bugs
- URL encoding fix for category names containing `&` (e.g., "Arts & Literature") — was silently breaking the API call
- Fixed `ai_difficulty` double-quoting bug on the server and repaired 9,332 existing rows in the database
- Server-side `?categories=` query parameter added to cardzerver `/api/v1/trivia/gamedata`
- 21 unit tests passing (including new round-robin balance test)

## What to Test

1. **Offline play**: Play one game online, then enable Airplane Mode and start another — should load from cache with orange "Offline mode" indicator
2. **Text size**: Change text size in home screen picker — verify it applies and persists after restarting the app
3. **Topic balance**: Start a game with exactly 2 topics on a 4x4 board — each topic should have 8 cells
4. **Category names with &**: Select "Arts & Literature" or "Science & Nature" — game should load questions correctly (was broken in build 16)
5. **AI text voice**: Finish a game and check the post-game analysis — should say "you" not "the player"
6. **Difficulty badges**: Check that Easy/Medium/Hard badges on questions look correct (server data is now clean)
7. **All board sizes**: Try 4x4 through 8x8, all three variants

## Known Issues
- App Clip store link is placeholder (id0000000000)
- Daily Challenge not yet functional (seed generation is TODO)
- Concentration variant is defined but hidden from UI picker
- Game Center entitlement not yet added — needs provisioning profile update

## Previous Builds
- Build 15: Welcome back confetti after 30min inactivity
- Build 14: Code review fixes — 10 bugs, consistency, safety
- Build 13: Wrap HomeView in ScrollView for small screens
- Build 4: Corner indicators, hint system, API URL fix
