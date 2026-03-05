# Qross — TestFlight Release Notes — Build 21 (0.2)

## What's New

**No More Repeated Questions**
- Server now tracks which questions you've already seen (per device)
- Each game serves fresh questions you haven't answered before
- When your pool runs low, a message tells you how many fresh questions remain
- Device identity is anonymous — no account required

**Share Code**
- Each game session gets a unique 6-character share code from the server
- Included in the share text when you share your result

**Text Size Control**
- New "Text Size" picker on the home screen: Small, Default, Large, XL
- Your preference persists across sessions

## Bug Fixes

**Ghost Answer Prevention**
- Fixed a bug where the 10-second auto-dismiss timer could fire after you already tapped OK, causing a double-answer on the same question

**Small Screen Support**
- Question overlay now scrolls on iPhone SE when questions are long or hints/explanations are shown
- Result overlay scrolls when many topics overflow the screen

**URL Encoding Fix**
- Categories with special characters (like "Arts & Literature") now load correctly — the `&` was being misinterpreted as a URL parameter separator

**App Clip Hardening**
- Added question count check before starting a game (prevents broken boards if API returns too few questions)
- Removed force unwrap on the App Store link
- Removed dead code that set a corner pair overwritten by game start

## Under the Hood
- Server-side seen-card tracking via `player_id` and `app_id` parameters
- `QuestionCache` filenames sanitized to handle topic names with `/` or `:` characters
- `topicColors` computed once on appear instead of every SwiftUI body evaluation
- Force unwrap on `URLComponents` replaced with proper error throw
- All version numbers synced across project.yml, Qross Info.plist, and QrossClip Info.plist
- 21 unit tests passing

## What to Test

1. **Fresh questions**: Play 2-3 games in a row — you should NOT see the same questions repeated
2. **Question exhaustion**: If you've played many games, check for a message about remaining fresh questions
3. **Share code**: Win a game, tap Share — the share text should include a 6-character code
4. **Text size**: Change text size on the home screen — verify it looks good at all 4 sizes
5. **Long questions on iPhone SE**: If available, play on a small screen device — question overlay and result screen should scroll when content overflows
6. **Fast tap on OK**: Answer a question, then immediately tap OK — should only register one answer (no double-count)
7. **Categories with &**: Select "Arts & Literature" or "Science & Nature" — should load without errors
8. **Offline play**: Play one game online, enable Airplane Mode, start another — should load from cache with orange "Offline mode" badge

## Known Issues
- App Clip store link is placeholder (id0000000000) — will be updated after App Store approval
- Daily Challenge not yet functional (seed generation is TODO)
- Concentration variant is defined but hidden from UI picker
- Game Center entitlement not yet added — needs provisioning profile update

## Previous Builds
- Build 17: Offline cache, round-robin balance, server-side filtering, AI voice fix
- Build 15: Welcome back confetti after 30min inactivity
- Build 14: Code review fixes — 10 bugs, consistency, safety
