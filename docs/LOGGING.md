# Logging

All logging goes through one class — `AppLogger` (`lib/services/app_logger.dart`).
Feature code must **never** call `print()` or `debugPrint()` directly (the analyzer's
`avoid_print` rule enforces the former); only `AppLogger` wraps them.

## Usage

```dart
import '../services/app_logger.dart';

AppLogger.d('Audio focus acquired');                 // debug trace
AppLogger.d('Permission status: $status', name: 'Mp3Picker'); // optional source tag
AppLogger.e('MP3 playback error', error: e, stackTrace: st);  // errors
```

- `AppLogger.d(message, {name})` — debug trace; `name` is an optional source tag.
- `AppLogger.e(message, {error, stackTrace})` — errors; prefer this in `catch` blocks.

## Single off switch

Every log is gated by one flag: `AppConfig.logEnabled` (`lib/config/app_config.dart`).
Because all logging funnels through `AppLogger`, logging can be turned off (or later
level-filtered / redirected) from that one place without touching call sites.

`debugPrint` appears in exactly one file — `app_logger.dart`. Everywhere else imports
`AppLogger`.

## Upgrade path

`AppConfig.logEnabled` is currently a compile-time `const bool`. To silence release
builds automatically, wire it to `kReleaseMode`; to add levels, add a `logLevel` to
`AppConfig` and check it inside `AppLogger`.
