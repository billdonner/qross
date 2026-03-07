# Qross User Manual

## 1. Welcome

Qross is a grid-based trivia game where you navigate from one corner of a colorful board to the opposite corner by answering questions correctly. Each cell holds a trivia question from a topic — strategy meets knowledge.

**Navigate. Answer. Conquer.**

## 2. Starting a Game

From the home screen:

1. **Quick Start** — Tap a preset (Quick Play, Challenge, or Expert) to set board size, variant, and mode in one tap.
2. **Topics** — Scroll the topic pills and tap to select/deselect. **At least 2 topics are required.** The app auto-selects popular topics to get you started.
3. **Settings** — Tap the **gear icon** (top-right) to open Settings, where you can adjust board size, variant, mode, Fast Game, haptics, and text size.
4. **Play** — Tap the Play button to generate your board and begin.

## 3. The Grid

The board is a square grid of colored cells. Each cell's color represents its **topic** — for example, blue for Science, orange for History. The colors help you plan your route through subjects you know well.

## 4. Picking Your Corner

When the board appears, all **4 corners** glow to indicate they're available. This is your first strategic decision:

1. Survey the board — look at which topics (colors) surround each corner.
2. Tap the corner where you want to **start**.
3. Answer the corner's question correctly to **lock in** your starting position.
4. The diagonally **opposite** corner automatically becomes your goal.

| You Pick | Your Goal |
|----------|-----------|
| Top-left | Bottom-right ↘ |
| Top-right | Bottom-left ↙ |
| Bottom-left | Top-right ↗ |
| Bottom-right | Top-left ↖ |

**Tip:** Choose the corner surrounded by topics you're strongest in.

## 5. Movement

Movement uses **8-direction adjacency** — you can move to any of the 8 cells surrounding your current position (up, down, left, right, and all 4 diagonals).

After each correct answer:
- Your position advances to that cell
- A glowing path connects your successful cells
- New adjacent cells become available (they pulse gently)

After a wrong answer:
- Your position does **not** move
- The cell is **burned** (blocked permanently)
- You lose one life

## 6. Winning and Losing

### Win
Answer the **goal corner** correctly. You'll see a celebration with your score and an option to share your result.

### Lose — Too Many Wrong
Each board size has a maximum number of wrong answers allowed. Exceed it and the game ends.

### Lose — Stuck
If no available cells are adjacent to your current position (all neighbors are burned or off-grid), the game ends.

## 7. Scoring

Your score is calculated as:

```
Score = moves + (wrong × 2) + hintPenalty
```

**Lower is better.** The minimum possible score equals the board size (a perfect diagonal with no wrong answers and no hints).

| Rating | Condition |
|--------|-----------|
| Perfect | Score equals minimum possible |
| Excellent | 1-2 above minimum |
| Good | 3-5 above minimum |
| Completed | Finished but above Good |
| Incomplete | Did not win |

## 8. Hints

During any question, two hint buttons may appear:

### Show Hint (+1)
- Reveals a text clue below the question
- Costs **1 point** added to your hint penalty
- Available only if the question has a hint

### Eliminate (+2)
- Removes one wrong answer choice from view
- Costs **2 points** added to your hint penalty
- Can be used multiple times (as long as 2+ wrong choices remain)

Hints are optional — use them strategically when stuck on a critical path cell.

## 9. AI Move Advisor

During gameplay, a purple banner at the top of the board suggests your best next move. The advisor evaluates every available cell — not just the shortest path — and considers:

- **Path to goal** — how many steps remain
- **Topic difficulty** — prefers easier topics when lives are low
- **Escape routes** — avoids dead ends and bottlenecks

A **risk badge** appears on the right side of the banner:

| Badge | Meaning |
|-------|---------|
| **Safe** (green shield) | Easy/medium topic, plenty of exits |
| **Caution** (orange triangle) | Hard topic or narrow corridor |
| **Risky** (red flame) | Hard topic + low lives, or dead-end ahead |

On devices with Apple Intelligence, the advisor explains *why* the move is best. Otherwise, a quick summary is shown (topic, difficulty, steps to goal).

Turn on **Fast Game** in Settings to disable all AI suggestions for a faster experience.

## 10. Variants

| Variant | What You See | Strategy |
|---------|-------------|----------|
| **Face Up** | All questions visible | Read every question, plan the perfect route, then execute |
| **Face Down** | Topic colors only, questions hidden | Route by topic color (your strengths), but questions are a surprise |
| **Blind** | No colors, no questions | Full fog of war — pure luck and adjacency awareness |

## 11. Board Size Reference

| Size | Total Cells | Min Path | Max Wrong | Difficulty |
|------|-------------|----------|-----------|------------|
| 4×4 | 16 | 4 | 2 | Beginner |
| 5×5 | 25 | 5 | 3 | Easy |
| 6×6 | 36 | 6 | 4 | Medium |
| 7×7 | 49 | 7 | 5 | Hard |
| 8×8 | 64 | 8 | 6 | Expert |

## 12. Sharing Results

After winning, tap **Share** to copy an emoji grid showing your path:

```
Qross 5×5 ↘ — 6 moves, 1 miss ✅
🟩🟩⬜⬜⬜
⬜🟩⬜⬜⬜
⬜🟩🟩⬜⬜
⬜⬜🟩🟥⬜
⬜⬜⬜🟩🟩
```

- 🟩 = correct answers (your path)
- 🟥 = wrong answers (burned cells)
- ⬜ = untouched cells

## 13. Tips & Strategy

1. **Survey before picking a corner.** Look at which topics cluster near each corner and choose one surrounded by your strongest subjects.
2. **Favor diagonal moves.** Diagonals cover the most ground toward your goal — each diagonal move advances both row and column.
3. **Avoid dead ends.** Before tapping a cell, check that it has multiple onward neighbors. A cell in a corner of burned cells can trap you.
4. **Use hints wisely.** A +1 hint on a must-win cell is worth the penalty. Burning a critical-path cell costs much more.
5. **Save the Eliminate hint for hard questions.** Removing one of four choices significantly improves your odds.
6. **Start small.** A 4×4 board is great for learning. Only 2 wrong answers allowed, but the path is short.
7. **In Face Up mode, plan your full route before your first move.** Read all the questions and map the easiest path.
8. **In Blind mode, stick to the diagonal.** With no information, the shortest path is your best bet.
