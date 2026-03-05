# Qross — TestFlight Release Notes — Build 22 (0.2)

## What's in This Build

This is the **first build submitted for external TestFlight review**. It contains the full Qross game experience.

## How to Play

- Pick a board size (4×4 to 8×8) and variant (Face Up / Face Down / Blind)
- Optionally filter by topic
- Tap **Play** — then tap any corner to start
- Answer questions correctly to move to adjacent cells
- Navigate from your starting corner to the diagonally opposite corner to win

## Features

- **3 variants**: Face Up (see all questions), Face Down (tap to reveal), Blind (no colors)
- **5 board sizes**: 4×4 through 8×8
- **Hints**: Show Hint (+1 penalty) or Eliminate a wrong answer (+2 penalty)
- **Move Advisor**: Apple Intelligence–powered path suggestions (devices with Apple Intelligence only; falls back to deterministic BFS suggestions)
- **Offline support**: Questions cached locally after first fetch
- **Double Cross mode**: Complete two diagonals back-to-back

## Known Issues / Not Yet in This Build

- App Clip not enabled (requires separate provisioning)
- Daily Challenge (same board for all players each day) — infrastructure exists, date seed not wired up yet
- Concentration variant hidden from UI — not yet implemented
- Game Center leaderboards not yet connected (entitlement pending)
- App Store link in App Clip placeholder (`id0000000000`)

## What to Test

1. Complete a full game on each board size (4×4 is quickest)
2. Try Face Down and Blind variants
3. Try using the hint system — verify penalty shows on result screen
4. Try getting the Move Advisor to fire (requires Apple Intelligence)
5. Force a loss by answering wrong repeatedly — verify loss screen appears
6. Play on poor/no network to verify offline cache kicks in
7. Kill app mid-game and relaunch — state does not persist (by design for beta)
