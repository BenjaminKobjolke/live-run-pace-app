# Settings Import / Export

Settings → Backup exports all settings to a JSON file and imports them back.
Implemented by `SettingsTransferService` (`lib/services/settings_transfer_service.dart`,
UI-free) and `BackupSettingsTab` (`lib/widgets/backup_settings_tab.dart`,
dialog mapping). Results are typed (`SettingsTransferResult`,
`lib/models/settings_transfer_result.dart`).

## Envelope

```json
{
  "formatVersion": 1,
  "app": "live_run_pace_app",
  "exportedAt": "2026-07-15T10:00:00.000",
  "sections": {
    "app_settings":     { ... },
    "tts_settings":     { ... },
    "screen_layouts":   { ... },
    "distance_history": { ... }
  }
}
```

Section names are the SharedPreferences keys (`StorageKeys` in
`storage_service.dart`) — the export maps 1:1 to storage.

**Included:** distance/paces (`app_settings`), TTS/gestures/MP3 list
(`tts_settings`), configurable run screens (`screen_layouts`), distance
suggestions (`distance_history`).

**Excluded:** `active_session` (importing another device's mid-run state
would be dangerous) and `session_history` (run data, not settings — possible
future opt-in).

## Compatibility rules

- `formatVersion` is checked on import; a **higher** version →
  `unsupportedVersion`, nothing written.
- Missing sections are skipped; each present section goes through its model's
  tolerant `fromJson` (missing fields → defaults, unknown fields ignored).
- Unknown **widget types** inside `screen_layouts` (from a newer app) are
  skipped per entry — the rest of the screen imports (see
  [SCREEN_LAYOUTS.md](SCREEN_LAYOUTS.md)).
- A file that fails top-level JSON parsing, or contains no known section →
  `invalidFile`, nothing written.
- A section that fails to apply is logged and skipped; successfully imported
  sections are reported in `SettingsTransferResult.importedSections`.

## Files & pickers (Android quirks)

- **Export:** `FilePicker.saveFile(..., bytes: ...)` — on Android the picker
  itself writes the bytes via SAF (no storage permission). The returned path
  may be a `content://` URI; it is only reported, never reopened with
  `dart:io`.
- **Import:** on Android ≤ 12 the storage permission is requested first
  (shared helper `lib/services/storage_permission.dart`, same cascade as the
  MP3 picker); Android 13+ needs none. The picker uses a `json` extension
  filter with a `FileType.any` fallback on Android ≤ 9, and `withData: true`
  so content URIs need no path access.

## Import vs the open settings draft

`SettingsScreen` edits a draft `TtsSettings` that is only persisted on Save.
A successful import immediately **pops the settings screen returning the
imported `TtsSettings`** so a later Save cannot overwrite the import with the
stale draft. `StartScreen` also reloads `AppSettings` after the pop.

## Statuses → dialogs

| Status | UI |
|---|---|
| `exported` / `imported` | info dialog |
| `cancelled` | silent |
| `invalidFile` / `unsupportedVersion` | info dialog explaining the file |
| `permissionDenied` | info dialog |
| `permissionPermanentlyDenied` | confirm dialog → `openAppSettings()` |
| `error` | info dialog with `errorDetails` |
