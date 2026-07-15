# Option Picker Screen

Generic full-screen list picker for the small target screen: a title, big tappable
option rows, and a Cancel button. Replaces inline selectors that made the input
screens too dense on 240x432.

File: `lib/screens/option_picker_screen.dart` — `OptionPickerScreen<T>` (stateless)
and `PickerOption<T>` (`label` + `value`).

## Contract

- **In:** `title` (`String`), `options` (`List<PickerOption<T>>`).
- **Out:** popped via `Navigator`:
  - Tap a row → that option's `value` (`T`).
  - **Cancel** / back → `null` (caller keeps its current selection).

Push with a typed route: `Navigator.push<T>(MaterialPageRoute(...))`.

## Consumers

- [Distance Input Screen](DISTANCE_INPUT_SCREEN.md) — unit picker (`m`/`km`/`mi`)
  and previous-distances picker (`double` values from
  `StorageService.getDistanceSuggestions`).
- [Pace Input Screen](PACE_INPUT_SCREEN.md) — unit picker (`km`/`mile`).
- [Widget Editor Screen](WIDGET_EDITOR_SCREEN.md) — widget type and the four
  placement fields (row/column/spans as `int` options).

## Layout

App shell pattern (`Scaffold(black)` → `SafeArea` → `Padding(16)` →
`Column(stretch)`): title, scrollable `ListView` of `MenuButton` rows, Cancel.

## Tests

`test/option_picker_screen_test.dart` — tapping a row pops its value; Cancel pops
`null`.
