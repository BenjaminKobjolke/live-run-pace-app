# Testing

Unit tests cover the pure logic — pace/time math, announcement text, and JSON
(de)serialization — the parts that must stay correct across refactors.

## Running

```bash
tools\run_tests.bat              # unit/widget tests (fvm flutter test)
tools\run_integration_tests.bat  # integration tests (skips if integration_test/ absent)
```

Or directly: `fvm flutter test`.

## What's covered

| File | Covers |
|------|--------|
| `test/app_settings_test.dart` | `AppSettings` time calc, pace/finish displays, JSON round-trip + defaults. |
| `test/running_session_test.dart` | `paceStatus` (±10% band), `timeLeftForCurrentKm`, `isOverTime`, partial-last-km, JSON round-trip. |
| `test/announcement_builder_test.dart` | Exact `AnnouncementBuilder.build` strings for on/behind/ahead schedule and final full/partial km. |
| `test/run_session_controller_test.dart` | `RunSessionController` km advance, pause/continue clock shift, finish, ChangeNotifier contract. |
| `test/tts_settings_test.dart` | `TtsSettings` legacy gesture-boolean migration, JSON round-trip, defaults. |
| `test/digit_keypad_test.dart` | `DigitKeypad` widget: digit/decimal/backspace callbacks, inert `.` when `allowDecimal: false`. |
| `test/distance_format_test.dart` | `formatDistance` trailing-zero trimming (`8.0 → "8"`, `8.5 → "8.5"`, partial zeros). |
| `test/option_picker_screen_test.dart` | `OptionPickerScreen`: tapping an option pops its value. |
| `test/pace_fields_row_test.dart` | Pace input row widget. |
| `test/mp3_shuffle_bag_test.dart` | `Mp3ShuffleBag` no-repeat shuffle cycle. |
| `test/run_screen_layout_test.dart` | Layout models: defaults replicate legacy screen, JSON round-trip, unknown-widget-type skip, placement clamping, orientation rule. |
| `test/run_widget_values_test.dart` | `runWidgetValue` type→getter mapping; loop over all `RunWidgetType`s (future-widget guard). |
| `test/run_widget_style_test.dart` | `valueStyle` auto/custom status coloring by `isOverTime`; `labelStyle` sizing. |
| `test/color_hex_test.dart` | `colorToHex` / `tryParseHexColor` round-trip + garbage rejection. |
| `test/storage_service_test.dart` | `screen_layouts` persistence: defaults fallback (missing/corrupt/empty), save round-trip. |
| `test/run_stat_tile_test.dart` | Stat tile: no overflow in the smallest cell, vertical vs horizontal orientation, label override. |
| `test/run_screen_grid_test.dart` | Grid geometry (fractional cells at 240×376), default layout renders, control gating. |
| `test/editable_screen_grid_test.dart` | WYSIWYG canvas: tap→cell/widget hit-testing, topmost-wins overlap, inert buttons. |
| `test/screen_editor_screen_test.dart` | Screen editor flows: add via empty cell (prefilled), edit, delete. |
| `test/widget_editor_screen_test.dart` | Widget editor: live preview reacts to sliders, Delete only in edit mode + confirm flow. |
| `test/settings_transfer_service_test.dart` | Export envelope, import round-trip, partial sections, invalidFile, unsupportedVersion. |

## Deterministic time

`RunningSession.elapsedTime` reads the wall clock (`now - startTime`) unless the
session is paused, in which case it freezes at `pausedAt`. Tests exploit this: they
build sessions with `pausedAt = startTime + elapsed`, so every time-derived getter is
deterministic without mocking the clock. The shared builder is `demoSession()`
(`lib/utils/demo_session.dart`) — it doubles as the demo data behind the WYSIWYG
editor and the widget-editor preview; `running_session_test.dart` keeps its own
local `_session` variant for model-specific parameters.

## Conventions

- Pure logic (models, `services/announcement_builder.dart`) is unit-testable with no
  widget or plugin — keep new pure logic in such classes so it can be tested directly.
- No network in unit tests. `main_screen`'s real-time coordination (timers, TTS,
  navigation) is verified by manual device smoke-test, not unit tests.
