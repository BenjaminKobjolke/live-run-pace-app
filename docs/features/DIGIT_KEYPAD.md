# Digit Keypad

On-screen numeric keypad that replaces the OS keyboard for small-screen numeric input.
The system keyboard covered the UI on the 240x432 target device — the keypad keeps input
on one full-screen view.

File: `lib/widgets/digit_keypad.dart` — `DigitKeypad` (stateless).

## Layout

```
1 2 3
4 5 6
7 8 9
. 0 <        (< = backspace, Icons.backspace)
```

Rows are `Expanded` and keys are `Expanded`, so the 3x4 grid fills whatever space the
parent gives it. Dark style matching the app: `Color(0xFF2A2A2A)` cells, white glyphs,
`Colors.white24` borders, green accents elsewhere on the hosting screens.

## API

The widget is **dumb** — it holds no value. The parent owns the edited string and reacts
to callbacks:

| Prop | Type | Fires on |
|---|---|---|
| `onDigit` | `ValueChanged<String>` | a digit `'0'`..`'9'` tapped |
| `onDecimal` | `VoidCallback` | `.` tapped (only when `allowDecimal`) |
| `onBackspace` | `VoidCallback` | `<` tapped |
| `allowDecimal` | `bool` (default `true`) | when `false`, `.` is greyed and inert |

The parent decides input rules (single decimal point, max digit count, leading-zero
handling, etc.) — the keypad only reports taps.

## Consumers

- `DistanceKeypadScreen` (see [Distance Input Screen](../screens/DISTANCE_INPUT_SCREEN.md))
  — `allowDecimal: true`.
- `PaceKeypadScreen` (see [Pace Input Screen](../screens/PACE_INPUT_SCREEN.md))
  — `allowDecimal: false` (integer minutes/seconds).

## Tests

`test/digit_keypad_test.dart` — verifies digit/decimal/backspace callbacks fire, and that
the `.` key is inert when `allowDecimal: false`.
