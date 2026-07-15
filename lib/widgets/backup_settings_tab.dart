import 'package:flutter/material.dart';
import '../models/settings_transfer_result.dart';
import '../services/settings_transfer_service.dart';
import '../services/storage_permission.dart';
import 'confirm_dialog.dart';
import 'info_dialog.dart';

/// Settings tab for exporting/importing all settings to/from a JSON file.
/// Maps [SettingsTransferResult] statuses to dialogs (same pattern as the
/// MP3 pick-result handling).
class BackupSettingsTab extends StatelessWidget {
  /// Called after a successful import so the host screen can reload and
  /// close with the freshly imported settings.
  final VoidCallback onImported;

  const BackupSettingsTab({super.key, required this.onImported});

  Future<void> _export(BuildContext context) async {
    final result = await SettingsTransferService().exportToFile();
    if (!context.mounted) return;
    switch (result.status) {
      case SettingsTransferStatus.exported:
        await showInfoDialog(
          context,
          title: 'Settings Exported',
          message: 'All settings were written to the selected file.',
        );
        break;
      case SettingsTransferStatus.cancelled:
        break;
      default:
        await _showError(context, result);
    }
  }

  Future<void> _import(BuildContext context) async {
    final result = await SettingsTransferService().importFromFile();
    if (!context.mounted) return;
    switch (result.status) {
      case SettingsTransferStatus.imported:
        await showInfoDialog(
          context,
          title: 'Settings Imported',
          message:
              'Restored ${result.importedSections.length} settings sections.',
        );
        onImported();
        break;
      case SettingsTransferStatus.cancelled:
        break;
      case SettingsTransferStatus.invalidFile:
        await showInfoDialog(
          context,
          title: 'Invalid File',
          message: 'The selected file is not a settings export of this app.',
        );
        break;
      case SettingsTransferStatus.unsupportedVersion:
        await showInfoDialog(
          context,
          title: 'Unsupported File',
          message:
              'This file was exported by a newer app version. Update the app and try again.',
        );
        break;
      case SettingsTransferStatus.permissionDenied:
        await showInfoDialog(
          context,
          title: 'Permission Required',
          message:
              'Storage permission is required to read the settings file.',
        );
        break;
      case SettingsTransferStatus.permissionPermanentlyDenied:
        final openSettings = await showConfirmDialog(
          context,
          title: 'Permission Denied',
          message:
              'Storage permission has been permanently denied. Please enable it in app settings.',
          confirmLabel: 'Settings',
        );
        if (openSettings) openAppSettings();
        break;
      default:
        await _showError(context, result);
    }
  }

  Future<void> _showError(
    BuildContext context,
    SettingsTransferResult result,
  ) {
    return showInfoDialog(
      context,
      title: 'Backup Error',
      message: result.errorDetails == null
          ? 'The operation failed.'
          : 'The operation failed.\n\nError: ${result.errorDetails}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Save all settings — paces, TTS, gestures, MP3 list and run '
            'screens — to a JSON file, or restore them from one.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _export(context),
            icon: const Icon(Icons.upload, color: Colors.white),
            label: const Text(
              'Export to file',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _import(context),
            icon: const Icon(Icons.download, color: Colors.white),
            label: const Text(
              'Import from file',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
