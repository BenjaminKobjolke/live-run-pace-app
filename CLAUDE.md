# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

**Coding rules source:** `D:\GIT\BenjaminKobjolke\claude-code\coding-rules` (`AI_RULES.md`, `COMMON_RULES.md`, `FLUTTER_RULES.md`). The [Coding Rules](#coding-rules) section below is derived from those files — refresh it via `/coding-rules:add-or-update`.

## Accepted Rule Exceptions

- **`lib/screens/main_screen.dart` exceeds the 300-line file limit (~420 lines).** It is a
  cohesive real-time session coordinator (session state, timers, app lifecycle, TTS lifecycle,
  gestures, navigation). Display pieces are already extracted to widgets
  (`RunHeader`, `RunStatsView`, `RunControls`, `PausedOverlay`) and announcement text to
  `AnnouncementBuilder`. Splitting the remaining logic cleanly needs a state-management layer
  (Cubit) the project does not use yet. Upgrade path: introduce `flutter_bloc` and move the
  mutation/timer logic into a `RunSessionCubit`.

## Code Analysis

After implementing new features or making significant changes, run the code analysis:

```bash
powershell -Command "cd 'D:\GIT\BenjaminKobjolke\live_run_pace_app'; cmd /c '.\tools\analyze_code.bat'"
```

Results are written to `code_analysis_results/` as **per-rule CSV files** (e.g.
`dart_analyze.csv`, `line_count_report.csv`, `duplicate_code.csv`) — there is
no `.md` report, and a missing CSV means that rule found nothing. Fix any
reported issues before committing.

## Project Overview

Live Run Pace App is a Flutter application designed for runners to track their pace and kilometer targets during runs. The app is optimized for small screen Android devices (240x432 resolution) and provides real-time pace feedback with multi-modal alerts (visual, haptic, audio).

## Development Commands

> **Flutter runs via [fvm](https://fvm.app), not a global `flutter` on PATH.**
> Version is pinned in `.fvmrc` (currently 3.44.1). Prefix every command with `fvm`:
> `fvm flutter run`, `fvm flutter analyze`, `fvm flutter pub get`, etc.
> Bare `flutter ...` fails with "'flutter' is not recognized".

### Initial Setup
```bash
# After cloning, regenerate platform directories
install.bat                    # Windows setup script
# OR manually:
flutter create . --platforms android,web
flutter pub get
```

### Running the App
```bash
flutter run                    # Android device/emulator
flutter run -d chrome          # Web browser
```

### Building
```bash
build_apk_quick.bat            # Quick debug APK build
build_apk_clean.bat            # Clean build with full cache clearing
flutter build apk             # Manual debug APK
flutter build web             # Web build
```

### Icon Generation
```bash
flutter pub run flutter_launcher_icons:main    # Generate app icons from assets/icons/icon.png
```

### Development Tools
```bash
flutter clean && flutter pub get    # Clean and refresh dependencies
flutter doctor                     # Check Flutter installation
```

## Architecture Overview

### Core Application Flow
1. **App Startup**: `AppLoader` checks for existing active sessions and routes accordingly
2. **Session Recovery**: Automatically resumes interrupted runs from persistent storage
3. **Settings Management**: Dual-pace system (target pace + max pace for when behind schedule)
4. **Audio Integration**: Complex TTS + custom MP3 + AIMP music player coordination

### Key Architectural Patterns

**Singleton Storage Service**: `StorageService.instance` manages all data persistence using SharedPreferences with JSON serialization.

**Session State Management**: Running sessions persist across app restarts with automatic recovery. The app maintains both active session state and session history.

**Audio Focus Architecture**: Multi-layered audio management:
- `TtsSpeaker` coordinates TTS announcements, custom MP3 playback, and audio focus
- Android native `MainActivity.kt` handles AIMP music player integration via method channels
- `audio_session` package manages proper audio interruption/resumption with other apps

**Dual-Pace System**: Uses both target pace and max pace to handle scenarios where runners fall behind schedule, switching to more aggressive pacing when needed.

### Data Models

**AppSettings**: Distance, target pace, and max pace configuration with time calculation utilities.

**RunningSession**: Tracks kilometer progress with `KilometerTarget` objects, calculates pace status (ahead/behind/on schedule), and manages session completion state.

**TtsSettings**: Comprehensive audio configuration including TTS parameters, multiple MP3 file paths with random selection, AIMP integration toggles, and gesture controls.

### Critical Android Integration

**Native Method Channels**: `com.yourapp.live_run_pace/aimp` channel in `MainActivity.kt` provides:
- `toggleAimp`: Alternates between play/pause for AIMP music player
- `resumeAimp`: Resumes AIMP after TTS announcements

**Permission Handling**: Complex Android version-specific permission logic in `tts_settings_dialog.dart`:
- Android 13+: Uses `Permission.audio`
- Android 12-: Uses `Permission.storage`
- Special handling for Android 8 file picker limitations

**File Management**: Supports both individual file selection and recursive folder scanning for audio files (MP3/WAV/M4A).

### UI Architecture

**Small Screen Optimization**: Designed for 240x432 resolution with space-efficient layouts and gesture controls.

**Gesture System**:
- Single tap main screen: AIMP play/pause toggle
- Double tap main screen: Mark kilometer completion (alternative to "GOT IT!" button)

**Color-Coded Feedback**: Green/red time displays based on pace status with synchronized visual flash and vibration.

### Audio Workflow

1. **TTS Announcement**: "The next target is kilometer X. You have Y minutes left..."
2. **Custom MP3**: Random selection from user's audio files plays after TTS
3. **Audio Focus Management**: Pauses other apps during announcements, resumes after
4. **AIMP Integration**: Automatically resumes music player after announcement sequence

## Platform-Specific Notes

### Android Requirements
- Minimum SDK 21 (Android 5.0+)
- Permissions: Storage/Audio, Vibration
- AIMP player integration requires AIMP app installation

### File Structure Considerations
- Platform directories (`android/`, `web/`) are git-ignored and regenerated via `install.bat`
- Custom app icons placed in `assets/icons/icon.png` and generated via flutter_launcher_icons
- Audio files supported: MP3, WAV, M4A with recursive folder scanning

### Testing and Debugging
The app includes extensive logging for audio focus management, TTS events, and AIMP integration. Use ADB logcat filtering for audio-related debugging:
```bash
adb logcat | findstr "Audio\|TTS\|MP3\|AIMP\|flutter"
```

## Common Development Patterns

When working with this codebase:
- Always check session state recovery in new features
- Audio features require careful focus management coordination
- UI changes should consider 240x432 screen constraints
- File operations need Android version-specific permission handling
- Settings changes should include JSON serialization support for persistence

# Coding Rules

Derived from the coding-rules repo. Rules for tech this app does not use (Dio/HTTP,
ObjectBox, Cubit/bloc, i18n/TK, Logarte, freezed) are intentionally omitted — add them
via `/coding-rules:add-or-update` if those dependencies are introduced.

## AI Workflow (always applies, language-independent)

After a plan is proposed and approved, follow this chain. The DRY gate is a precondition
for implementing — not just an earlier step:

```
plan approved
  → /plan:dry            check approved plan for DRY/consolidation BEFORE code
  → /plan:dry-checked    reload + review the DRY-adjusted plan
  → /convention:check    scan for existing patterns/components to reuse
  ─────────────────────  DRY GATE — must be cleared to proceed
  → restate Definition-of-Done aloud
  → implement
  → /dry:check           post-implementation DRY audit
  → /verify:after-change run tests + code analysis
```

**DRY gate (precondition for implementing).** Do not write a line until ALL are true; restate aloud when you start implementing:
- [ ] `/plan:dry` ran and the plan was adjusted for any duplication found.
- [ ] `/plan:dry-checked` reloaded and confirmed the adjusted plan.
- [ ] `/convention:check` found the existing utilities/patterns to reuse.

The gate survives the `implement` step: if mid-implementation you add a new helper, type, or pattern the gate would have caught, stop and re-clear it.

**Definition of Done — restate aloud before the first edit:** Scope (what changes, what does not); Reuse (existing fn/component + path); DRY gate cleared; `/dry:check` clean; `/verify:after-change` green.

**Bug fixes** use a shorter variant (no plan-DRY phase): `bugs:fix → /verify:after-change`.

## Common Rules (all apply)

- **Use objects for related values.** Bundle related values passed between classes/methods into a DTO/Settings/Config object instead of many parameters.
- **No bag-of-keys returns at module boundaries.** Public manager/service/repository methods that cross a module boundary return a typed object (DTO, value object, domain model) — never a raw `Map`/array keyed by strings. Distinguish absent (`null`) from empty (empty collection). Internal private helpers may stay maps.
- **Reuse existing models before inventing shapes.** Search for an existing domain class that owns the same data before creating a new DTO. A `getXxxObject()` alongside a legacy `getXxxData()` is an acceptable migration step — delete the old one once consumers migrate.
- **Tests pin the shape before a refactor.** Write a characterization test against the current API, run it green, then refactor; keep it green after.
- **Test-Driven Development.** Write tests first → confirm they fail → implement → confirm they pass.
- **Integration tests** required in addition to unit tests.
- **Test runner scripts** required: `tools/run_tests.bat`, `tools/run_integration_tests.bat`.
- **Prefer type-safe values.** Strong explicit types (typed DTOs, enums, typed settings) over stringly-typed values.
- **String constants** centralized in a dedicated module/class — no scattered raw strings.
- **Reusable tooling.** Before building project infra scripts, check the language's `*_setup_files/` folder for an existing equivalent; if you build a new one, copy it back and document it.
- **README.md mandatory** — name/description, setup, usage, dependencies.
- **DRY.** Extract duplicated logic into a reusable function/class/module; constants for repeated values.
- **Derive, don't duplicate.** When one value strictly determines another (a functional dependency), pass only the determinant and derive the rest via a cheap pure getter/exhaustive match — never thread both side-by-side.
- **KISS / YAGNI.** Simplest solution that works. No interface with one impl, no factory for one product, no config for a value that never changes. Boring over clever; deletion over addition.
- **Confirm dependency versions** with the user before adding any new package.
- **Error handling & logging strategy.** Centralized error handler, not scattered ad-hoc try/catch. Structured logging at proper levels with context.
- **Centralized logger — single off switch.** Route all logging through one class **`AppLogger`** (`app_logger.dart`). Never call `print()`, `developer.log`, or the `logger` package directly from feature code — only `AppLogger` wraps them. One config toggle controls enable/level/sink.
- **Input validation at boundaries** — user input, files, external responses. Fail fast with clear messages.
- **Max file length 300 lines.** Split by domain. Exceptions: generated, config, test files.
- **Naming conventions.** Files `snake_case`; classes `PascalCase`; Dart methods/vars `camelCase`; constants `UPPER_SNAKE_CASE`.
- **Comments explain why, not what.** Document intent, workarounds, non-obvious constraints; delete stale comments. Document each module/class purpose at top.
- **Security baseline.** Never commit secrets. Escape output. Parameterized queries. Validate input at boundaries. Keep deps updated.
- **No hardcoded environment values** (paths, hosts, IPs, ports, URLs) — read from central config with a committed `.example` template.
- **No god classes.** Warning signs: >5 public methods, >4 constructor deps, unrelated-domain methods. Split by responsibility. "Manager/Handler/Service/Helper" as the only name it fits = it does too much.
- **Self-describing classes.** When behavior depends on which fields a class has (search, serialization, display, validation), the class declares its own fields via a contract (interface/mixin) — never a hardcoded field list in consuming code.
- **Inject collaborators, don't fold dependencies in.** Prefer injected collaborators over mixin/trait fold-in (which merges the helper's deps into the host). Never `new` a service inside a method — inject it via the constructor. Collapse config-callback getter swarms into one value object.

## Flutter Rules (applicable subset)

### Core principles
1. Composition over inheritance — small, focused widgets.
2. Testability — each widget testable in isolation.
3. Single Responsibility — one widget = one job.
4. Reusability.
5. Readability — smaller files (~100–200 lines).
6. Follow SOLID.

### Documentation comments
Every public class, method, and property gets a `///` doc comment. Reference params with `[paramName]`. Keep descriptions concise. Do not use `//` block comments for documentation.

### `part` / `part of`
Prefer normal `import`/`export` for all hand-written code. Use `part` only when a code generator requires it (`*.g.dart`, `*.freezed.dart`) or for one tightly-coupled library sharing library-private members. Never use `part` to split a large class or organize features.

### Mixins
Reach for a mixin only when composition (injected helper/field) does not fit — a mixin is inheritance.
1. Use the `mixin` keyword, never a `class` as a mixin (`mixin class` only when a type must serve as both).
2. Constrain with `on HostType` when the mixin depends on a host — restricts application and grants typed host access.
3. Keep mixins stateless (mixin members live in the host scope; a mutable field silently couples/collides). If state is unavoidable: one `_`-prefixed documented field.
4. One capability per mixin — no `UtilsMixin` grab-bag.
5. Name by capability (`-able` suffix or `Mixin` suffix).
6. Only call `super.method()` when the `on` constraint guarantees it; know linearization order for lifecycle overrides.
7. Mark host-only members `@protected`; `///` doc every public member.
8. If the behavior owns state or deps, make it a class and inject with `GetIt` — not a mixin.

### FVM
Flutter runs via FVM, version pinned in `.fvmrc`. Prefix every command with `fvm` (`fvm flutter pub get`, `fvm flutter run`, `fvm flutter analyze`).

### Linting & formatting
`fvm flutter analyze` and `fvm dart format lib/`. `analysis_options.yaml` includes `package:flutter_lints/flutter.yaml`; enforce `prefer_const_constructors`, `prefer_const_declarations`, `avoid_print`.

### Centralize configuration
No magic values in code. Use an `AppConfig` class (`lib/config/app_config.dart`) with `private._()` constructor and `static const` values. Secrets go in `.env` (gitignored) with a committed `.env.example` — never in source.

### Logging & error handling
Route all logging through `AppLogger` (`app_logger.dart`) — never `print()`/`developer.log`/`logger` directly in feature code. Try-catch all async/critical ops. Show user-friendly messages, never raw exceptions. Log with context (class, method, params).

### Tests mandatory
`fvm flutter test`. Unit tests for services/business logic; widget tests for UI; no network in unit tests (mock); run in CI.

### Required batch files
`install.bat`, `update.bat` (root); `tools/run_tests.bat`, `tools/build_debug.bat`, `tools/build_release.bat`.

### Dependency injection
Use `GetIt` for service location — register at startup, retrieve via `GetIt.instance` — to keep services decoupled and testable.

### Widget rebuild optimization
`const` constructors wherever possible; extract subtrees into separate widgets to limit rebuild scope; avoid large widget trees in one `build`; use `buildWhen`/`BlocSelector` to rebuild only on relevant state change.

### Self-describing classes (Dart)
Implement via an abstract class or mixin returning the class's own fields:
```dart
abstract class Searchable {
  Map<String, String> getSearchableFields();
}
```

### Coupling: mixins, widgets, injected services
- `with SomeMixin` folds the mixin's dependencies into the widget/class — prefer a child widget or injected service for anything carrying dependencies; keep mixins small and dependency-free.
- A god `build()` that wires many services and prop-drills through layers depends on everything it drills through. Extract child widgets; pass a single config object or read shared state via a provider/`InheritedWidget`.