# MP3 Settings Tab

Third tab of the full-screen [Settings screen](../SETTINGS.md) (`TTS | Gestures | MP3`).
Manages the list of audio files (MP3/WAV/M4A) that play — shuffled, no repeat until
every file has played — after each kilometer-completion TTS announcement.

Files:

| File | Role |
|------|------|
| `lib/widgets/mp3_settings_tab.dart` | `Mp3SettingsTab` — tab body (header, list, Add/Refresh buttons). Stateless; all picking logic injected via callbacks. |
| `lib/widgets/mp3_file_list.dart` | `Mp3FileList` — scrollable selected-files list with per-row preview/remove and Clear All; owns a single preview `AudioPlayer`. |
| `lib/services/mp3_picker_service.dart` | `Mp3PickerService` — UI-free picking, permissions, recursive folder scan, `rescanFolder`. |
| `lib/models/mp3_pick_result.dart` | `Mp3PickStatus` / `Mp3PickResult` — typed pick outcomes. |
| `lib/screens/settings_screen.dart` | Hosts the tab; maps `Mp3PickResult` to dialogs / `setState`; owns `_mp3FilePaths` / `_mp3FolderPath`. |

## Contract

- **In:** `filePaths` (current list), `enabled` (mirrors the TTS master toggle — when
  TTS is off, every control here is disabled), callbacks `onRemove`, `onClearAll`,
  `onPickFiles`, `onPickFolder`, `onRefreshFolder` (nullable — null hides the button).
- **Out:** nothing directly. Edits accumulate in `SettingsScreen` state; the AppBar
  **Save** pops the whole `TtsSettings` (fields `mp3FilePaths`, `mp3FolderPath`) back
  to `StartScreen`, which persists it. Back arrow discards everything.

## Layout (top → bottom)

1. Header `MP3 Sound After TTS` + right-aligned file count (`N files`, hidden when empty).
2. **File list** (only when non-empty; max height 360, scrolls):
   - Per row: ▶/■ preview toggle, file name (basename, ellipsized), × remove.
   - **Clear All** footer row — only when more than one file.
3. **Add Files** / **Add Folder** buttons, side by side.
4. **Refresh Folder** — only after a folder has been picked (`mp3FolderPath != null`).

## Behavior

- **Add Files** — multi-select picker; duplicates against the current list are skipped.
- **Add Folder** — directory picker, recursive scan for `mp3`/`wav`/`m4a`; folder is
  remembered in `mp3FolderPath` so Refresh works.
- **Refresh Folder** — re-scans the remembered folder without a picker dialog,
  appending only new files. Add-new-only: never removes deleted tracks — prune via ×
  or Clear All.
- **Preview** — one shared `AudioPlayer`; starting a preview stops any other, ■ or
  natural completion stops it. Independent of runtime playback in `tts_speaker.dart`.
- **Permissions** — Android 13+ `Permission.audio`, older `Permission.storage`;
  permanently-denied offers a jump to app settings. Version-specific picker fallbacks
  (`FileType.audio` → `custom` → `any` on Android ≤ 8).
- **Pick outcomes** — `Mp3PickStatus` (`added`, `cancelled`, `permissionDenied`,
  `permissionPermanentlyDenied`, `emptyFolder`, `noNewFiles`, `error`) each map to an
  info/confirm dialog or a state update in `settings_screen.dart`.

## Runtime playback

How the saved list is actually used (shuffle-bag pick after km-completion TTS,
audio-focus handling, the `delayAfterAudioMs` tail-drain) is documented in
[SETTINGS.md → Post-TTS MP3 playback](../SETTINGS.md#post-tts-mp3-playback).

## Persistence

`mp3FilePaths` / `mp3FolderPath` live in `TtsSettings`, JSON-persisted by
`StorageService` under the `tts_settings` key. Legacy single `mp3FilePath` string
migrates into the list on load.
