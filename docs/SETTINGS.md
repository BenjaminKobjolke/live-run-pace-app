# Settings Screen

Full-screen settings page. Configures TTS, audio behavior, gestures, and post-TTS
MP3 playback.

The controls are split across **three swipeable tabs** (`TabBar` + `TabBarView`
under a `DefaultTabController` in `settings_screen.dart`) — swipe left/right or tap
a tab:

| Tab | Contents |
|-----|----------|
| **TTS** | TTS Enabled, Speed, Volume, Delay after audio, Pause other apps audio, Resume AIMP after playback |
| **Gestures** | Touch to toggle AIMP, Double tap to complete km, Delay button navigation |
| **MP3** | The MP3 file list (with per-file preview playback) + Add Files / Add Folder |

The single **Save** action lives in the AppBar and applies across all tabs.

## Files

| File | Role |
|------|------|
| `lib/screens/settings_screen.dart` | `SettingsScreen` — the full-screen UI (thin: state + result handling). |
| `lib/models/tts_settings.dart` | `TtsSettings` — immutable data model + JSON (de)serialization. |
| `lib/services/mp3_picker_service.dart` | `Mp3PickerService` — UI-free file/folder picking, permissions, and recursive scan; returns a typed `Mp3PickResult`. |
| `lib/widgets/mp3_settings_tab.dart` | `Mp3SettingsTab` — the MP3 tab body (header, list, Add Files/Folder buttons); picking injected via callbacks. |
| `lib/widgets/mp3_file_list.dart` | `Mp3FileList` — the selected-files list (preview ▶ / remove / Clear All); owns a preview `AudioPlayer`. |
| `lib/widgets/setting_controls.dart` | `SettingSwitch` / `SettingSlider` — reusable labeled rows. |
| `lib/widgets/confirm_dialog.dart`, `info_dialog.dart` | Shared `showConfirmDialog` / `showInfoDialog` helpers. |
| `lib/services/storage_service.dart` | Persists to `SharedPreferences` under key `tts_settings`. |
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
| `touchToToggleAimp` | Switch | on/off | `false` | Single tap on main screen plays/pauses AIMP. |
| `doubleTapToCompleteKm` | Switch | on/off | `false` | Double tap on main screen marks a kilometer complete. |
| `buttonNavigationDelay` | Switch | on/off | `true` | Adds a delay before button navigation on the main screen. |
| `delayAfterAudioMs` | Slider | 0–3000 ms, 100 ms steps | `1000` | Tail-drain delay after each MP3 finishes, before the player is torn down. Lets the last buffered audio play out (some devices otherwise clip the last 1-2s). |
| `mp3FilePaths` | File/folder pickers + list | list of paths | `[]` | MP3/WAV/M4A files played (random pick) after each TTS announcement. |

### MP3 selection

Picking/scanning logic lives in `Mp3PickerService` (UI-free); `SettingsScreen`
maps the returned `Mp3PickResult.status` to a dialog or a state update. This keeps
the screen thin and makes the picker testable.

- **Add Files** — multi-select picker (`file_picker`). Falls back across
  `FileType.audio` → `custom` → `any` depending on Android version.
- **Add Folder** — picks a directory, recursively scans for `mp3`/`wav`/`m4a`.
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
`TtsSpeaker.speak(text, {playMp3})`. A random file from `mp3FilePaths` plays via
`audioplayers` (`DeviceFileSource`) **only when `playMp3: true`** — used for
kilometer-completion announcements. Pause/resume announcements call `speak()` with
the default `playMp3: false`, so they never trigger an MP3.

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
single `mp3FilePath` string is migrated into the `mp3FilePaths` list. Missing
keys fall back to the defaults above.

## History

Previously a floating `AlertDialog` (`lib/widgets/tts_settings_dialog.dart`,
title "TTS Settings"). Converted to a full screen to use the whole viewport on
small devices (240×432) and renamed "Settings". The old widget file was deleted.
