# Sessions

How a running session is created, persisted, recovered, paused, and finished.

## Storage

All persistence goes through `StorageService` (singleton, `StorageService.instance`)
backed by `SharedPreferences` with JSON serialization. Two distinct keys:

- `active_session` — the **single** in-progress run. At most one exists.
- `session_history` — a **list** of finished (`isCompleted`) or aborted (`isAborted`) runs.

`saveActiveSession` / `loadActiveSession` / `clearActiveSession` manage the active
run; `saveSessionToHistory` / `loadSessionHistory` / `deleteSession` manage history.

## Data model

`RunningSession` (`lib/models/running_session.dart`) holds:

- `id`, `distance`, `targetPace`, `maxPace`, `startTime`
- `targets` — list of `KilometerTarget` (`kmNumber`, `completedAt`, `actualTime`)
- `currentKm` — 1-based index of the km the runner is working toward
- `isCompleted`, `isAborted`, `pausedAt`

Everything time-related is **derived live** from `startTime`, not stored:

- `elapsedTime => (pausedAt ?? now).difference(startTime)` — the clock. Frozen while paused.
- `timeLeftForCurrentKm`, `finishTimeDisplay`, `paceStatus` (ahead / on / behind, ±10% band),
  partial-last-km handling — all computed from `elapsedTime` + pace.

Because time is derived, there is nothing to tick or persist per second; a saved
`startTime` is enough to reconstruct the full clock on reload.

Display-only formatting getters (`finishTimeDisplay`, `timeLeftDisplay`,
`currentSegmentDistanceDisplay`, `averagePaceDisplay`, `statusDisplay`,
`completionSummary`, …) live in an extension in
`lib/models/running_session_display.dart`, re-exported from `running_session.dart`
so importing the model gives them automatically. This keeps display concerns out
of the domain model.

## Lifecycle

1. **Create** — `MainScreen._initializeSession`. If no `existingSession` is passed,
   build a fresh `RunningSession` with one `KilometerTarget` per km (`distance.ceil()`),
   `startTime = now`, save it as the active session, record the distance to history.
2. **Run / autosave** — two 10s `Timer.periodic` (`_startTimers`): one repaints the
   UI, one autosaves the active session. Also saved immediately on every km change
   (`_goToNextKm` / `_goToPreviousKm`).
3. **Complete a km** — "GOT IT!" button or double-tap (if enabled) → `_goToNextKm`
   stamps the current target's `completedAt` / `actualTime`, advances `currentKm`,
   fires feedback (flash + vibrate + TTS announcement), saves. The announcement text
   is built by `AnnouncementBuilder.build(session)` (`lib/services/announcement_builder.dart`,
   pure + unit-tested) and spoken with `playMp3: true` so the post-TTS MP3 plays.
4. **Finish** — on the last km the button becomes "FINISH!" → confirm dialog →
   `_finishSession`: stamp final target, set `isCompleted`, push to history, clear
   the active session, go to `CompletionScreen`.
5. **Abort** — the ✕ button → confirm dialog → `_abortSession`: set `isAborted`,
   push to history, clear the active session, return to `HomeScreen`.

## Gestures (main screen)

The main content area is one `GestureDetector` (`MainScreen.build`, wrapping the
`RunStatsView` widget) carrying three gestures. They coexist — Flutter
disambiguates by tap count / hold duration. The build is composed of extracted
widgets: `RunHeader` (top bar + abort ✕), `RunStatsView` (live stats),
`RunControls` (back / GOT IT–FINISH buttons), and `PausedOverlay`.

| Gesture | Action | Guard |
|---|---|---|
| Single tap | Toggle AIMP music player (play/pause) | `ttsSettings.touchToToggleAimp` |
| Double tap | Complete current km — same as "GOT IT!" | `ttsSettings.doubleTapToCompleteKm` **and** `_buttonsEnabled` |
| Long press | Pause the session (see [Pause](#pause)) | `_buttonsEnabled` |

`_buttonsEnabled` is briefly false (~1s) right after a km change when
`ttsSettings.buttonNavigationDelay` is on, to avoid accidental double-advances;
long-press and double-tap are suppressed during that window.

## Recovery

`AppLoader._checkForExistingSession` (`lib/main.dart`) runs on launch:

- Loads `active_session`. If present **and not completed**, reopens `MainScreen`
  with it as `existingSession` — the run continues where it left off.
- Otherwise goes to `HomeScreen`.

Since the clock is derived from `startTime`, a recovered run shows the correct
elapsed time even after the app was closed for a while.

## Background

`didChangeAppLifecycleState` in `MainScreen`:

- `paused` / `detached` / `hidden` → stop timers, save the session.
- `resumed` → restart timers (unless paused — see below).

The wall clock keeps advancing while backgrounded (elapsed time is `now - startTime`),
which is intended: a real run doesn't stop because the screen turned off.

## Pause

Distinct from backgrounding — an explicit, deliberate stop that **freezes the clock**.

- **Trigger** — long-press the main screen (coexists with tap→AIMP and double-tap→complete).
- **Pause** (`_pauseSession`) — set `pausedAt = now`, stop timers, save. While
  `pausedAt` is set, `elapsedTime` uses it as "now", so every displayed value holds
  still. The full-screen `PausedOverlay` widget (large **CONTINUE** button) covers the UI.
- **Continue** (`_continueSession`) — shift `startTime` forward by the paused gap
  (`now - pausedAt`), clear `pausedAt`, restart timers, save. The absorbed gap means
  the clock resumes exactly where it stopped — the pause never counts as run time.
- **TTS** — if TTS is enabled in settings, pause speaks "Session paused." and
  continue speaks "Session resumed." (`TtsSpeaker.speak` no-ops when TTS is off).
- **Persisted** — `pausedAt` is part of the session JSON. If the app is killed while
  paused, recovery reopens the run **still paused** (overlay shown, clock frozen);
  Continue resumes cleanly. No time is lost.

## Gotcha: copyWith and null

`RunningSession.copyWith` uses the `value ?? this.value` idiom, which **cannot** set a
field back to `null`. To clear `pausedAt`, pass `clearPausedAt: true` (the continue
handler does this). The same limitation applies to `KilometerTarget.completedAt` /
`actualTime` — don't rely on `copyWith` to null them.
