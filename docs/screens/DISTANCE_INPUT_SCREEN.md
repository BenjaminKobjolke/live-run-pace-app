# Distance Input Screen

Compact editor for the run **distance**, sized for the 240x432 target screen. The
screen itself only shows the value and navigation buttons — editing happens on
full-screen sub-screens (keypad, unit picker, previous-distances picker) pushed on
top.

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
2. Tappable value box (`ValueDisplay`, e.g. `10 km`) → pushes the **keypad
   sub-screen** (below).
3. `Unit: km` button (`MenuButton`) → pushes an
   [`OptionPickerScreen`](OPTION_PICKER_SCREEN.md) with `m` / `km` / `mi`; picking a
   unit **converts** the current value.
4. `Previous Distances` button → pushes an `OptionPickerScreen<double>` filled from
   `StorageService.getDistanceSuggestions(limit: 6)` (labels via `formatDistance` +
   ` km`); picking one sets the value in km. Hidden while loading or if empty.
5. Spacer, then Cancel / OK (`InputActions`).

## Keypad sub-screen

`lib/screens/distance_keypad_screen.dart` — `DistanceKeypadScreen`. Full-screen
editor: large value display + [`DigitKeypad`](../features/DIGIT_KEYPAD.md)
(`allowDecimal: true`) + Cancel/OK.

- **In:** `initialValue` (`String`, raw text), `unit` (`String`, display suffix).
- **Out:** the edited raw `String` on OK, `null` on cancel (parent keeps its value).
- Keypad rules: digit appends; decimal appends `.` only if none present (`''` →
  `0.`); backspace trims the last char.
- A blinking cursor (`BlinkingCursor`, `lib/widgets/blinking_cursor.dart`) sits
  between the value and the unit suffix (`ValueDisplay.showCursor` / `suffix`).

## State & value

- `String _value` — raw text in the selected `_unit`. Init from
  `formatDistance(currentDistance)` (`lib/utils/distance_format.dart` — up to 6
  decimals, trailing zeros trimmed, so a saved `8.0` reopens as `8` and a typed
  `42.12234` keeps all its digits).
- `_enteredValue` getter parses `_value` and converts to km (`km` as-is, `m` /1000,
  `mi` /0.621371).
- Unit pick converts `_value` into the new unit so the displayed number stays
  equivalent.

## History

Was a single packed screen (value + unit row + suggestion chips + inline keypad +
actions) — too dense for 240x432. Before that, a `widgets/distance_dialog.dart`
`AlertDialog` with OS-keyboard `TextField`s. Return contract unchanged throughout,
so start-screen save logic was never touched.
