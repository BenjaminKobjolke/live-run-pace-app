# Settings Screen

Full-screen settings page. Configures TTS, audio behavior, gestures, and post-TTS
MP3 playback.

## Files

| File | Role |
|------|------|
| `lib/screens/settings_screen.dart` | `SettingsScreen` — the full-screen UI. |
| `lib/models/tts_settings.dart` | `TtsSettings` — immutable data model + JSON (de)serialization. |
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

- **Add Files** — multi-select picker (`file_picker`). Falls back across
  `FileType.audio` → `custom` → `any` depending on Android version.
- **Add Folder** — picks a directory, recursively scans for `mp3`/`wav`/`m4a`.
- Duplicates are filtered; each file has an × to remove; **Clear All** appears
  when more than one file is present.
- **Permissions:** Android 13+ (SDK 33+) requests `Permission.audio`; older uses
  `Permission.storage`. Denied/permanently-denied/empty-folder/error cases each
  show a nested `AlertDialog` (these dialogs are fine layered over the full screen).

## Persistence & compatibility

`StorageService` JSON-encodes `TtsSettings.toJson()` into `SharedPreferences`
(key `tts_settings`). `TtsSettings.fromJson` is backward-compatible: an old
single `mp3FilePath` string is migrated into the `mp3FilePaths` list. Missing
keys fall back to the defaults above.

## History

Previously a floating `AlertDialog` (`lib/widgets/tts_settings_dialog.dart`,
title "TTS Settings"). Converted to a full screen to use the whole viewport on
small devices (240×432) and renamed "Settings". The old widget file was deleted.
