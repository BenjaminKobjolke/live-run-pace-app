# Settings Screen

Full-screen settings page. Configures TTS, audio behavior, gestures, post-TTS
MP3 playback, the configurable run screens, and settings backup.

The controls are split across **five swipeable tabs** (`TabBar` with
`isScrollable: true` — five fixed tabs would not fit 240 px — + `TabBarView`
under a `DefaultTabController` in `settings_screen.dart`):

| Tab | Contents |
|-----|----------|
| **TTS** | TTS Enabled, Speed, Volume, Delay after audio, Pause other apps audio, Resume AIMP after playback, **Test Voice** — see [screens/TTS_SETTINGS_TAB.md](screens/TTS_SETTINGS_TAB.md) |
| **Gestures** | Single tap / Double tap / Long press → action dropdowns, Delay button navigation — see [screens/GESTURE_SETTINGS_TAB.md](screens/GESTURE_SETTINGS_TAB.md) |
| **MP3** | The MP3 file list (with per-file preview playback) + Add Files / Add Folder / **Refresh Folder** — see [screens/MP3_SETTINGS_TAB.md](screens/MP3_SETTINGS_TAB.md) |
| **Screens** | The configurable run screens (widgets, placement, colors) — see [screens/SCREENS_SETTINGS_TAB.md](screens/SCREENS_SETTINGS_TAB.md) and [SCREEN_LAYOUTS.md](SCREEN_LAYOUTS.md) |
| **Backup** | Export / import all settings to a JSON file — see [screens/BACKUP_SETTINGS_TAB.md](screens/BACKUP_SETTINGS_TAB.md) and [IMPORT_EXPORT.md](IMPORT_EXPORT.md) |

The **Save** action in the AppBar applies to the TTS/Gestures/MP3 draft
(`TtsSettings`). The Screens tab persists its layouts **immediately** on every
change (`screen_layouts` key) — it is independent of Save. A successful
import in the Backup tab pops the whole settings screen with the imported
`TtsSettings` so the open draft cannot overwrite it.

## Files

| File | Role |
|------|------|
| `lib/screens/settings_screen.dart` | `SettingsScreen` — the full-screen UI (thin: state + result handling). |
| `lib/models/tts_settings.dart` | `TtsSettings` — immutable data model + JSON (de)serialization. |
| `lib/models/gesture_action.dart` | `GestureAction` — enum of actions assignable to a gesture (with display `label`). |
| `lib/models/mp3_pick_result.dart` | `Mp3PickStatus` / `Mp3PickResult` — typed outcomes for file/folder picking. |
| `lib/services/mp3_picker_service.dart` | `Mp3PickerService` — UI-free file/folder picking, permissions, recursive scan, and `rescanFolder`; returns a typed `Mp3PickResult`. |
| `lib/widgets/mp3_settings_tab.dart` | `Mp3SettingsTab` — the MP3 tab body (header, list, Add Files/Folder + Refresh buttons); picking injected via callbacks. |
| `lib/widgets/tts_settings_tab.dart` | `TtsSettingsTab` — TTS controls, audio focus switches, and Test Voice button. |
| `lib/widgets/gesture_settings_tab.dart` | `GestureSettingsTab` — per-gesture action dropdowns and navigation delay switch. |
| `lib/widgets/mp3_file_list.dart` | `Mp3FileList` — the selected-files list (preview / remove / Clear All); owns a preview `AudioPlayer`. |
| `lib/widgets/setting_controls.dart` | `SettingSwitch` / `SettingSlider` / `SettingDropdown<T>` / `ColorSettingRow` — reusable labeled rows. |
| `lib/widgets/mp3_pick_result_handler.dart` | `showMp3PickResultDialogs` — maps `Mp3PickResult` failure statuses to dialogs. |
| `lib/widgets/screens_settings_tab.dart` | `ScreensSettingsTab` — run-screen list (self-persisting). |
| `lib/screens/screen_editor_screen.dart`, `lib/widgets/editable_screen_grid.dart` | WYSIWYG screen editor + its tap-to-edit canvas. |
| `lib/screens/widget_editor_screen.dart`, `lib/screens/color_picker_screen.dart` | Widget property form (with live tile preview) and the full-screen color picker. |
| `lib/screens/number_picker_screen.dart`, `lib/widgets/picker_bottom_bar.dart` | Full-screen slide-up/down number picker (sizes) + shared Cancel/OK bar. |
| `lib/utils/demo_session.dart` | Frozen demo `RunningSession` feeding the editor previews (and the test suites). |
| `lib/widgets/backup_settings_tab.dart` | `BackupSettingsTab` — export/import buttons + dialog mapping. |
| `lib/services/settings_transfer_service.dart` | `SettingsTransferService` — settings export/import (see [IMPORT_EXPORT.md](IMPORT_EXPORT.md)). |
| `lib/services/storage_permission.dart` | Shared Android storage-permission cascade (`androidSdkInt`, `storagePermissionForDevice`) used by the MP3 picker and the import. |
| `lib/widgets/confirm_dialog.dart`, `info_dialog.dart` | Shared `showConfirmDialog` / `showInfoDialog` helpers. |
| `lib/services/storage_service.dart` | Persists to `SharedPreferences` (`StorageKeys`: `tts_settings`, `screen_layouts`, …). |
| `lib/screens/start_screen.dart` | Opens the screen (gear icon) and owns persistence. |
| `lib/services/tts_speaker.dart` | Consumes the settings at runtime. |

## Navigation & save contract

Opened from `StartScreen`'s gear icon via `Navigator.push<TtsSettings>` (matches
the app's imperative `MaterialPageRoute` pattern — no named routes).

- **AppBar back arrow** → cancel: `Navigator.pop()` with no value. Nothing saved.
- **AppBar "Save"** → `Navigator.pop(newSettings)` returns the edited `TtsSettings`.

The **caller owns persistence**. `SettingsScreen` only edits local state and
returns the object; `StartScreen._showTtsSettingsDialog()` then does:

```dart
final newSettings = await Navigator.of(context).push<TtsSettings>(
  MaterialPageRoute(builder: (c) => SettingsScreen(currentSettings: _ttsSettings)),
);
if (newSettings != null) {
  setState(() => _ttsSettings = newSettings);
  await _saveTtsSettings();   // -> StorageService.saveTtsSettings
}
```

`initState()` seeds local fields from `widget.currentSettings`, so the screen
opens showing the last-saved values.

## Settings

| Field (`TtsSettings`) | Control | Range / values | Default | Effect |
|---|---|---|---|---|
| `enabled` | Switch | on/off | `true` | Master TTS toggle. When off, Speed/Volume/MP3 controls are disabled. |
| `speed` | Slider | 0.1–1.0, 9 divisions | `0.4` | TTS speech rate. |
| `volume` | Slider | 0.5–2.0, 15 divisions | `1.5` | TTS volume. |
| `pauseOtherAudio` | Switch | on/off | `true` | Grab audio focus during announcements (pauses other apps). Gates "Resume AIMP". |
| `resumeAimpAfterPlayback` | Switch | on/off | `false` | Auto-resume AIMP after the TTS+MP3 sequence. Only editable when `pauseOtherAudio` is on. |
| `singleTapAction` | Dropdown | `GestureAction` | `none` | Action for a single tap on the main run screen. |
| `doubleTapAction` | Dropdown | `GestureAction` | `none` | Action for a double tap on the main run screen. |
| `longPressAction` | Dropdown | `GestureAction` | `pause` | Action for a long press on the main run screen. |
| `buttonNavigationDelay` | Switch | on/off | `true` | Adds a delay before button navigation on the main screen. |
| `delayAfterAudioMs` | Slider | 0–3000 ms, 100 ms steps | `1000` | Tail-drain delay after each MP3 finishes, before the player is torn down. Lets the last buffered audio play out (some devices otherwise clip the last 1-2s). |
| `mp3FilePaths` | File/folder pickers + list | list of paths | `[]` | MP3/WAV/M4A files played (shuffled, no repeat until all played) after each TTS announcement. |
| `mp3FolderPath` | (set by Add/Refresh Folder) | path or null | `null` | Last-picked MP3 folder. Enables the **Refresh Folder** re-scan. |

### Test Voice

The TTS tab has a **Test Voice** button (below "Resume AIMP"). It speaks a sample
phrase at the *current, unsaved* Speed/Volume slider values so the user can tune by ear
before saving. It builds a throwaway `TtsSpeaker` from `currentSettings.copyWith(...)`
with `pauseOtherAudio: false`, `resumeAimpAfterPlayback: false`, and empty
`mp3FilePaths` — so it never grabs audio focus, plays an MP3, or resumes AIMP; a clean,
isolated preview. The button is disabled while speaking (`speak()` awaits completion).

### Gesture actions

`GestureAction` (`lib/models/gesture_action.dart`): `none`, `toggleAimp`, `completeKm`,
`previousKm`, `pause`, `abort`. Each of the three gestures (single tap / double tap /
long press) picks one via a `SettingDropdown`. `main_screen.dart`'s single
`GestureDetector` resolves each to a handler via `_gestureCallback`, preserving prior
gating: `completeKm`/`previousKm`/`pause` respect the button debounce (`_buttonsEnabled`);
`toggleAimp`/`abort` are ungated (`abort` has its own confirm dialog). `none` disables the
gesture. `completeKm`/`previousKm` route through the widget-level `_onNext`/`_onPrevious`
so their dialogs, screen-flash, and vibration are preserved.

**Backward compatibility:** `TtsSettings.fromJson` migrates the old booleans when the new
keys are absent — `touchToToggleAimp: true → singleTapAction: toggleAimp`,
`doubleTapToCompleteKm: true → doubleTapAction: completeKm`, and long press defaults to
`pause` (its former hardwired behaviour).

### MP3 selection

Picking/scanning logic lives in `Mp3PickerService` (UI-free); `SettingsScreen`
maps the returned `Mp3PickResult.status` to a dialog or a state update. This keeps
the screen thin and makes the picker testable.

- **Add Files** — multi-select picker (`file_picker`). Falls back across
  `FileType.audio` → `custom` → `any` depending on Android version.
- **Add Folder** — picks a directory, recursively scans for `mp3`/`wav`/`m4a`. The chosen
  folder is remembered in `mp3FolderPath` (surfaced via `Mp3PickResult.folderPath`).
- **Refresh Folder** — re-scans the remembered `mp3FolderPath` (no picker dialog) via
  `Mp3PickerService.rescanFolder`, appending audio files not already listed. Only shown once
  a folder has been picked. **Add-new-only:** it never removes files — deleted tracks are not
  pruned (the flat list has no folder provenance); use each row's × or **Clear All** to drop
  files. `pickFolder` and `rescanFolder` share the scan/dedup logic (`_scanFolderResult`).
- Duplicates are filtered; each file has an × to remove; **Clear All** appears
  when more than one file is present (`Mp3FileList`).
- Each row has a ▶ **preview** button — tap to play the file for testing, tap ■ to
  stop (switching to another file stops the previous one). `Mp3FileList` owns a
  single preview `AudioPlayer`, disposed with the widget. This is independent of the
  runtime TTS playback in `tts_speaker.dart`.
- **Permissions:** Android 13+ (SDK 33+) requests `Permission.audio`; older uses
  `Permission.storage`.
- **Result → UI:** `Mp3PickStatus` values — `added`, `cancelled`,
  `permissionDenied`, `permissionPermanentlyDenied` (offers a "Settings" jump via
  `showConfirmDialog` → `openAppSettings`), `emptyFolder`, `noNewFiles`, `error` —
  each map to `showInfoDialog` / `showConfirmDialog` or a `setState` add. These
  dialogs are fine layered over the full screen.

## Post-TTS MP3 playback

Handled at runtime by `tts_speaker.dart` → `_playMp3WithFocus`, called from
`TtsSpeaker.speak(text, {playMp3})`. A file from `mp3FilePaths` plays via
`audioplayers` (`DeviceFileSource`) **only when `playMp3: true`** — used for
kilometer-completion announcements. Pause/resume announcements call `speak()` with
the default `playMp3: false`, so they never trigger an MP3.

Selection is a **shuffle bag** (`Mp3ShuffleBag`, `lib/services/mp3_shuffle_bag.dart`,
unit-tested): each file plays once in random order before any repeats, and no file
plays twice in a row across bag refills (unless only one file is configured). The bag
lives in the `TtsSpeaker` instance, which lives for the whole run session — restarting
the app mid-run resets the cycle.

Completion handling:

- The player is set to `ReleaseMode.stop` (not the default `release`) so it stays
  alive after playback and its buffered tail can keep draining.
- Wait for `onPlayerComplete` (end-of-**data**), with a 30s timeout backstop.
- Then wait `delayAfterAudioMs` to let the hardware buffer drain, and finally call
  `stop()` to free the player for the next playback. There is **no**
  `PlayerState.stopped` listener — under `ReleaseMode.stop` it would race natural
  completion and cut the tail early.

**Why `delayAfterAudioMs` exists:** on Android, `onPlayerComplete` fires at
end-of-**data** while ~1-2s of decoded audio is still queued in the hardware
buffer. Tearing the player down immediately clips the tail. The delay drains it
first. Per-device tuning knob — default 1000 ms; `0` disables the wait.

## Persistence & compatibility

`StorageService` JSON-encodes `TtsSettings.toJson()` into `SharedPreferences`
(key `tts_settings`). `TtsSettings.fromJson` is backward-compatible: an old
single `mp3FilePath` string is migrated into the `mp3FilePaths` list, and the old
`touchToToggleAimp` / `doubleTapToCompleteKm` gesture booleans migrate into the new
`GestureAction` fields (see [Gesture actions](#gesture-actions)). Missing keys fall back to
the defaults above.

## History

Previously a floating `AlertDialog` (`lib/widgets/tts_settings_dialog.dart`,
title "TTS Settings"). Converted to a full screen to use the whole viewport on
small devices (240×432) and renamed "Settings". The old widget file was deleted.
