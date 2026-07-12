# Pace Input Screen

Full-screen editor for a **pace** (minutes : seconds per km/mile), driven by an
on-screen digit keypad instead of the OS keyboard. Used for **both** target pace and
max pace.

File: `lib/screens/pace_input_screen.dart` — `PaceInputScreen`.

## Contract

- **In:**
  - `currentPace` (`Duration`) — shown when the screen opens.
  - `title` (`String`) — heading, `'Target Pace'` or `'Max Pace'`.
- **Out:** popped via `Navigator`:
  - **OK** → entered `Duration`.
  - **Cancel** / back → `null`.

Opened from `StartScreen._showTargetPaceDialog` / `_showMaxPaceDialog` with
`Navigator.push<Duration>(MaterialPageRoute(...))`, passing the matching `title`. On a
non-null result the start screen updates the pace minutes/seconds and saves.

## Layout (top → bottom)

1. Title (`Target Pace` / `Max Pace`).
2. Two tappable value boxes `MM : SS`, plus `/ unit`. The **active** field has a green
   border; tap a box to select it.
3. Unit selector `km` / `mile`.
4. [`DigitKeypad`](../features/DIGIT_KEYPAD.md) (`allowDecimal: false` — the `.` key is
   greyed and inert).
5. Cancel / OK actions.

## State & value

- `String _minutes`, `String _seconds` — init from `currentPace`
  (`inMinutes`, `inSeconds % 60`, seconds zero-padded).
- `int _activeField` — `0` = minutes, `1` = seconds. Default `0`.
- Digit → appended to the active field, **max 2 digits**; a lone leading `0` is
  overwritten by the first real digit. Backspace trims the active field.
- `_pace` getter → `Duration(minutes, seconds)` parsed from the two fields. Unchanged
  from the previous dialog.

Note: the unit selector (`km`/`mile`) is display-only, matching the original dialog — it
does not scale the entered numbers.

## History

Replaced the old `widgets/pace_dialog.dart` `AlertDialog` + two OS-keyboard `TextField`s.
Return contract is unchanged.
