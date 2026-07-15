# Backup Settings Tab

`lib/widgets/backup_settings_tab.dart` — the Settings → Backup tab:
**Export to file** and **Import from file** buttons for all settings.

Delegates to `SettingsTransferService` and maps every
`SettingsTransferStatus` to a dialog (permission-permanently-denied offers
the app-settings jump, like the MP3 flow). After a successful import the tab
calls `onImported`, which makes `SettingsScreen` pop with the freshly
imported `TtsSettings` — closing the screen prevents the still-open draft
from overwriting the import via a later Save.

Details of the file format and compatibility rules:
[IMPORT_EXPORT.md](../IMPORT_EXPORT.md).
