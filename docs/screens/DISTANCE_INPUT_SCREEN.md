# Distance Input Screen

Full-screen editor for the run **distance**, driven by an on-screen digit keypad
instead of the OS keyboard (which covered the UI on the 240x432 target screen).

File: `lib/screens/distance_input_screen.dart` — `DistanceInputScreen`.

## Contract

- **In:** `currentDistance` (`double`, kilometres) — shown when the screen opens.
- **Out:** popped via `Navigator`:
  - **OK** → the entered value converted to **kilometres** (`double`).
  - **Cancel** / back → `null` (caller leaves settings unchanged).

Opened from `StartScreen._showDistanceDialog` with
`Navigator.push<double>(MaterialPageRoute(...))`. On a non-null result the start
screen does `_settings.copyWith(distance: ...)` and saves.

## Layout (top → bottom)

1. Title `Distance`.
2. Read-only value display box (`_value` + unit suffix, green border).
3. Unit selector `m` / `km` / `mi` — switching **converts** the current value.
4. "Frequently Used" chips from `StorageService.getDistanceSuggestions(limit: 6)`;
   tapping one sets the value in km. Hidden while loading or if empty. Chip labels
   use `formatDistance` (trailing zeros trimmed).
5. [`DigitKeypad`](../features/DIGIT_KEYPAD.md) (`allowDecimal: true`) filling the
   remaining space.
6. Cancel / OK actions.

## State & value

- `String _value` — raw text being edited, in the selected `_unit`. Init from
  `formatDistance(currentDistance)` (`lib/utils/distance_format.dart` — up to 3
  decimals, trailing zeros trimmed, so a saved `8.0` reopens as `8`, not `8.000`).
- Keypad handlers: digit appends; decimal appends `.` only if none present (`''` →
  `0.`); backspace trims the last char.
- `_enteredValue` getter parses `_value` and converts to km (`km` as-is, `m` /1000,
  `mi` /0.621371). Same math as the previous dialog.
- Unit toggle converts `_value` into the new unit so the displayed number stays
  equivalent.

## History

Replaced the old `widgets/distance_dialog.dart` `AlertDialog` + OS-keyboard
`TextField`. Return contract is unchanged, so start-screen save logic was untouched.
