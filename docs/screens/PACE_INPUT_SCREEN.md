# Pace Input Screen

Compact editor for a **pace** (minutes : seconds per km/mile), sized for the 240x432
target screen. Used for **both** target pace and max pace. The screen itself only
shows the value and buttons — editing happens on full-screen sub-screens (keypad,
unit picker) pushed on top.

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
2. Two tappable value boxes `MM : SS / unit` (`PaceFieldsRow`,
   `lib/widgets/pace_fields_row.dart` — shared with the keypad sub-screen) →
   tapping **minutes** or **seconds** pushes the **keypad sub-screen** (below) with
   that field already active.
3. `Unit: km` button (`MenuButton`) → pushes an
   [`OptionPickerScreen`](OPTION_PICKER_SCREEN.md) with `km` / `mile`.
4. Spacer, then Cancel / OK (`InputActions`).

Note: the unit is display-only, matching the original dialog — it does not scale the
entered numbers.

## Keypad sub-screen

`lib/screens/pace_keypad_screen.dart` — `PaceKeypadScreen`. Full-screen editor: the
same `PaceFieldsRow` (`MM : SS / unit`), then
[`DigitKeypad`](../features/DIGIT_KEYPAD.md) (`allowDecimal: false` — the `.` key is
greyed and inert) + Cancel/OK.

- **In:** `initialPace` (`Duration`), `unit` (`String`, display suffix),
  `initialField` (`int`, 0 = minutes / 1 = seconds — the field active on open,
  set by which box was tapped on the compact screen).
- **Out:** entered `Duration` on OK, `null` on cancel (parent keeps its value).
- The **active** field has a green border and a blinking cursor
  (`BlinkingCursor`, `lib/widgets/blinking_cursor.dart`) after its value; tap a
  box to select it. Digit → appended to the active field, **max 2 digits**; a lone
  leading `0` is overwritten by the first real digit. Backspace trims the active
  field.

## State

The compact screen holds a single `Duration _pace` (init from `currentPace`) and the
display `_unit`. Field splitting/joining lives entirely in `PaceKeypadScreen`.

## History

Was a single packed screen (fields + unit row + inline keypad + actions) — too dense
for 240x432. Before that, a `widgets/pace_dialog.dart` `AlertDialog` with two
OS-keyboard `TextField`s. Return contract unchanged throughout.
