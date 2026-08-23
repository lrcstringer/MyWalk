# WIP — Scripture Memorization Initial Flow Redesign — DONE

## Implemented (this session)
Full redesign of `initial_memorization_screen.dart`.

### Changes summary
- **3 steps** (was 4): Listen, Read Aloud, Quick Flip
- **Step 1 (Listen)**: "Next phrase" disabled until Play Audio tapped (`_hasPlayed` flag, resets per chunk)
- **Step 2 (Read Aloud)**:
  - States: `initializing | preview | listening | scored`
  - `preview`: verse at full brightness + "Ready to recite from memory" button
  - Tapping that → `listening` state (verse gone, pulsing mic, Done button)
  - Removed `if (result.finalResult) _score()` auto-score
  - `pauseFor` raised to 8s (was 3s)
  - "Done reading" → scores if transcript non-empty, skips to next if empty
  - STT unavailable: preview button says "Read it aloud — tap to continue" → onNext()
- **Step 3 (Quick Flip)**: `_FlipFillStep` manages two sequential exercises per chunk
  - **Exercise A — Flip**: Proper 3D flip (Matrix4 rotateY 0→π), front = `chunk.hint` (golden monospace), back = `chunk.text` + `item.title` + "I knew it ✓" / "I didn't know ✗" buttons with haptics → advances to Exercise B
  - **Exercise B — Fill In**: Parses `chunk.hint` (underscore `_` = blank slot) vs `chunk.text` for expected chars. Hidden 1-char TextField captures keyboard. Per-slot first-attempt scoring: correct on first try → green + locked + advance; wrong → red, user can backspace and retype (first fail already recorded). Score = `_successCount / totalSlots`. "Clear" button for explicit backspace. Once all slots locked → score badge + "Next chunk"/"Finish" button.

### Files changed
- `lib/presentation/views/memorization/screens/initial_memorization_screen.dart` — complete rewrite

### dart analyze result
No issues found!
