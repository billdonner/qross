# Qross — Game Design Document

## Overview

Qross is a grid-based trivia game where players navigate from one corner of a colored matrix to the opposite corner by answering questions correctly. Each cell belongs to a topic with its own color. Strategy (routing) meets knowledge (answering).

## Topics

There are between 1 and 26 Topics active in the Game at any point in time. Topics are named categories like Movies, Music, Food, or very specifically "German Movies of the 20's and 30's". Topics are sourced from card-engine trivia decks.

### Current Topic Pool (from card-engine)

| Topic | Questions Available |
|-------|-------------------|
| Vehicles | 731 |
| Video Games | 685 |
| Arts & Literature | 554 |
| Comics | 550 |
| Board Games | 537 |
| Society & Culture | 528 |
| Music | 523 |
| Technology | 519 |
| Food & Drink | 494 |
| Mathematics | 480 |
| Literature | 462 |
| Pop Culture | 453 |
| Politics | 438 |
| Film & TV | 432 |
| Sports | 379 |
| History | 378 |
| Science & Nature | 364 |
| Mythology | 363 |
| Geography | 226 |
| General Knowledge | 156 |
| World Geography | 50 |

### Challenges

Challenges are trivia questions with 4 multiple-choice answers. Each challenge has:
- Question text
- 4 choices (one correct)
- Difficulty (easy, medium, hard)
- Topic assignment
- Hint (optional)
- Explanation (shown after answering)

### Selection of Topics

Before each game the player chooses topics. Rules:
- Minimum 1 topic, maximum varies by board size
- Each topic must have enough questions to fill its cells
- At advanced levels, the game forces 1-2 topics the player didn't choose
- "Surprise Me" option picks topics randomly

### Topic Colorization

Each topic gets a color assigned at game start. Colors are chosen from a curated palette designed to be distinguishable on both light and dark backgrounds. The palette avoids red/green adjacency for color-blind accessibility.

## Game Board

The board is a square matrix of cells. Each cell contains one Challenge, colored by its topic.

### Board Sizes

The UI picker offers sizes 4 through 8:

| Size | Cells | Min Path | Max Wrong | Recommended Topics |
|------|-------|----------|-----------|--------------------|
| 4×4 | 16 | 4 | 4 | 2-4 |
| 5×5 | 25 | 5 | 10 | 3-5 |
| 6×6 | 36 | 6 | 10 | 3-6 |
| 7×7 | 49 | 7 | 10 | 4-7 |
| 8×8 | 64 | 8 | 10 | 5-8 |

Min Path = minimum moves with 8-connectivity (the diagonal).

## Start and End Positions

### Pick Any Corner (Implemented)

At game start, all 4 corners are highlighted. The player taps any corner to begin:
1. That corner's question is presented
2. A correct answer **locks** it as the start position
3. The diagonally opposite corner automatically becomes the goal

| Corner Picked | Goal | CornerPair |
|---------------|------|------------|
| Top-left (0,0) | Bottom-right (N,N) | Classic ↘ |
| Top-right (0,N) | Bottom-left (N,0) | Reverse ↙ |
| Bottom-left (N,0) | Top-right (0,N) | Uphill ↗ |
| Bottom-right (N,N) | Top-left (0,0) | Downhill ↖ |

This gives the player strategic choice — scan the board for favorable topics near each corner before committing.

### Edge-to-Edge Mode (Future)

Player taps any cell on the top or left edge to start. The end cell is the mirror-opposite on the bottom or right edge. Not yet implemented.

### Random Corners (Future)

Game randomly picks two opposite corners. Player doesn't know which until the board appears. Not yet implemented.

### Daily Challenge

Fixed start/end for the day. Same for all players. Seeded by date.

## Movement Rules

### Adjacency (8-connected)

From any cell, the player can move to up to 8 neighbors:
```
[NW] [N ] [NE]
[W ] [X ] [E ]
[SW] [S ] [SE]
```

### Move Sequence

1. Game highlights available cells (adjacent to last successful cell)
2. Player taps an available cell
3. Question overlay appears (anchored to that cell)
4. Player answers:
   - **Correct**: Cell marked successful, becomes new position, path extends
   - **Wrong**: Cell marked failed (burned), position stays at previous cell, life lost
5. Game recalculates available cells from current position
6. Repeat until win or lose

### Key Rules

- Wrong answers do NOT advance position
- Burned cells are permanently blocked (cannot be retried)
- Available cells = neighbors of last successful cell that are not burned and not already completed
- Completed cells can be passed through (they don't block adjacency)

## Win and Lose Conditions

### Win
- Player answers the end cell correctly
- Celebration animation, score displayed, share card generated

### Lose — Too Many Wrong
- Player exceeds wrong answer limit for the board size
- Board reveals with optimal path highlighted

### Lose — Stuck
- No available cells adjacent to current position
- All neighbors are burned or off-grid
- Board reveals with optimal path highlighted

### First/Last Cell Special Rules

The first and last cells must be answered correctly. Special handling:

**First cell miss:**
- Option A: Free retry (no penalty), different question from same topic
- Option B: Offer to switch to the opposite diagonal (one-time option)

**Last cell miss:**
- Counts as a normal wrong answer
- If lives remain, player can try to reach the end cell from an adjacent completed cell
- The end cell gets a new question from the same topic

## Hints

The question overlay offers two hint types before the player answers:

### Show Hint (+1 penalty)
- Available when the challenge has a `hint` field
- Reveals a text hint below the question
- Can only be used once per question
- Adds **1** to `hintPenalty`

### Eliminate (+2 penalty)
- Removes one wrong answer choice from the visible options
- Keeps at least 1 wrong choice visible (so there's always a real choice)
- Can be used multiple times per question (as long as 2+ wrong choices remain)
- Each use adds **2** to `hintPenalty`

Hint costs are cumulative and added to the final score.

## Scoring

```
Score = moves + (wrong × 2) + hintPenalty
```

Lower is better. The theoretical minimum on a 5×5 is 5 (perfect diagonal, no wrongs, no hints).

### Score Ratings

| Rating | Score vs Minimum |
|--------|-----------------|
| Perfect | Equals minimum path |
| Excellent | Minimum + 1-2 |
| Good | Minimum + 3-5 |
| Completed | Finished but above Good |

## Game Modes

Game mode controls the **win condition structure** — how many legs must be completed to win. This is separate from the variant (which controls board visibility).

### Single (Default)
Standard one-diagonal game. Navigate from your starting corner to the opposite corner. This is the classic Qross experience.

### Double Cross
Two-leg game. After completing the first diagonal, the player must continue to one of the two remaining corners:

1. Player picks a starting corner and navigates to the opposite corner (Leg 1)
2. Upon reaching the opposite corner, the two remaining corners pulse
3. Player taps one of the remaining corners to set it as the new goal
4. Player navigates from the Leg 1 endpoint to the chosen corner (Leg 2)
5. Answering the final corner correctly wins the game

**Key rules for Double Cross:**
- Board state fully carries over between legs (correct cells traversable, burned cells stay blocked)
- Wrong answer count and score accumulate across both legs
- No extra lives between legs — this makes Double Cross genuinely harder
- Score formula is unchanged: `moves + (wrong × 2) + hintPenalty` across both legs
- Minimum possible score is `2 × board_size` (two diagonals)

**Second corner pick phase:**
Between legs, only the two remaining corners are available (regardless of adjacency). This is a special "pick your target" phase — the player selects which corner to aim for, then must navigate there normally via adjacency.

## Game Variants

### Face Up
All questions are visible on the board from the start. The player can read every question before choosing a path. This is pure strategy mode — plan the full route, then execute.

### Face Down (Default)
Only topic colors are shown. Questions are revealed only when the cell is tapped. This is the standard mode — route by topic color (your strengths), but questions are a surprise.

### Blind
No colors, no questions visible. Complete fog of war. Only the start and end cells are marked. Maximum difficulty.

### Concentration (Even boards only: 4×4, 6×6, 8×8)
- Each question appears in exactly two random cells
- Player must find and tap both matching cells before answering
- If the match is correct: both cells are marked successful
- If wrong: both cells are burned
- Colors may or may not be shown (difficulty setting)
- All other movement rules apply
- Very easy to get stuck — designed as an expert mode

## Daily Challenge

### How It Works
1. A seed is generated from the current date: `seed = hash(YYYY-MM-DD)`
2. The seed determines: board size (5×5), topics (3), question selection, cell layout, start/end
3. Every player gets the identical board
4. One attempt per day
5. Results posted to Game Center daily leaderboard

### Share Card
After completing (win or lose), the player can share a visual grid:
```
Qross Daily #42 — 7 moves, 1 miss ⭐
🟩🟩⬜⬜⬜
⬜🟩⬜⬜⬜
⬜🟩🟩⬜⬜
⬜⬜🟩🟩⬜
⬜⬜⬜🟩🟩
```

## App Clip

The App Clip is a lightweight version for instant play:
- Triggered by: shared link, QR code, Messages, Safari banner
- Experience: 5×5 board, Face Down, 3 pre-selected popular topics
- No sign-in, no onboarding
- Shows score at end → "Get Qross for daily challenges & more"
- Must be under 15MB (App Clip size limit)
- Shares all game logic code with the main app

## Future Considerations

- **Multiplayer real-time**: Two players race on the same board simultaneously
- **Team mode**: Two players alternate answering on the same board
- **Custom topic packs**: User-created or imported question sets
- **Seasonal themes**: Halloween, holiday, etc. visual themes
- **Achievements**: Game Center achievements for milestones
- **Streaks**: Daily challenge streak tracking
- **Replays**: Watch your path replay animated, or watch a friend's
