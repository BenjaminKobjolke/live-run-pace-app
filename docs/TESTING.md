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

## Deterministic time

`RunningSession.elapsedTime` reads the wall clock (`now - startTime`) unless the
session is paused, in which case it freezes at `pausedAt`. Tests exploit this: they
build sessions with `pausedAt = startTime + elapsed`, so every time-derived getter is
deterministic without mocking the clock. See the `_session(...)` helper in the tests.

## Conventions

- Pure logic (models, `services/announcement_builder.dart`) is unit-testable with no
  widget or plugin — keep new pure logic in such classes so it can be tested directly.
- No network in unit tests. `main_screen`'s real-time coordination (timers, TTS,
  navigation) is verified by manual device smoke-test, not unit tests.
