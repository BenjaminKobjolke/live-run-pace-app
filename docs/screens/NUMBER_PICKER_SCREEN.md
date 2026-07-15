# Number Picker Screen

`lib/screens/number_picker_screen.dart` — fullscreen integer picker for the
small target screen: the current value rendered huge in the center; **slide
up/down anywhere to change it** (up = increase, ~12 px per step —
`_pixelsPerStep`, a tuning constant), − / + buttons for single-step
precision, a min–max hint line, and the shared Cancel / OK bottom bar
(`lib/widgets/picker_bottom_bar.dart`, also used by the color picker).

## Contract

- **In:** `title`, `value`, `min`, `max` (ints; initial value is clamped).
- **Out:** popped via `Navigator` — **OK** → the picked `int`; **Cancel** /
  back → `null` (caller keeps its current value).

## Consumers

- [Widget Editor Screen](WIDGET_EDITOR_SCREEN.md) — label size (8–24), value
  size / button size (12–72); the editor converts to/from `double`.

## Tests

`test/number_picker_screen_test.dart` — initial value, ± stepping and
clamping, drag up/down with clamping, OK/Cancel pop contract.
