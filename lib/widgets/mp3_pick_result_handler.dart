import 'package:flutter/material.dart';
import '../models/mp3_pick_result.dart';
import '../services/storage_permission.dart';
import 'confirm_dialog.dart';
import 'info_dialog.dart';

/// Maps the failure/empty statuses of an [Mp3PickResult] to user dialogs.
/// Extracted from SettingsScreen so the screen stays a thin tab host.
/// The success bookkeeping (adding paths, remembering the folder) stays with
/// the caller — this only talks to the user.
Future<void> showMp3PickResultDialogs(
  BuildContext context,
  Mp3PickResult result, {
  required bool isFolder,
}) async {
  switch (result.status) {
    case Mp3PickStatus.added:
    case Mp3PickStatus.cancelled:
      break;
    case Mp3PickStatus.permissionDenied:
      await showInfoDialog(
        context,
        title: 'Permission Required',
        message:
            'Storage permission is required to select MP3 files. Please grant permission and try again.',
      );
      break;
    case Mp3PickStatus.permissionPermanentlyDenied:
      final openSettings = await showConfirmDialog(
        context,
        title: 'Permission Denied',
        message:
            'Storage permission has been permanently denied. Please enable it in app settings to select MP3 files.',
        confirmLabel: 'Settings',
      );
      if (openSettings) openAppSettings();
      break;
    case Mp3PickStatus.emptyFolder:
      await showInfoDialog(
        context,
        title: 'No Audio Files Found',
        message:
            'The selected folder does not contain any audio files (MP3, WAV, M4A).',
      );
      break;
    case Mp3PickStatus.noNewFiles:
      await showInfoDialog(
        context,
        title: 'No New Files Added',
        message:
            'All ${result.totalFound} audio files from the selected folder are already in your list.',
      );
      break;
    case Mp3PickStatus.error:
      await showInfoDialog(
        context,
        title: isFolder ? 'Folder Selection Error' : 'File Selection Error',
        message: _pickerErrorMessage(result, isFolder: isFolder),
      );
      break;
  }
}

String _pickerErrorMessage(Mp3PickResult result, {required bool isFolder}) {
  final what = isFolder ? 'folder' : 'file';
  if (result.androidVersion != 0 && result.androidVersion <= 28) {
    final alternative = isFolder
        ? 'You can also manually select individual files instead.'
        : 'You can also manually copy MP3 files to Downloads folder.';
    return '${isFolder ? 'Folder' : 'File'} picker issue on Android ${result.androidVersion}. Please try:\n\n'
        '1. Go to Android Settings → Apps → Live Run Pace → Permissions\n'
        '2. Enable "Storage" permission\n'
        '3. Restart the app and try again\n\n$alternative';
  }
  if (result.errorDetails != null) {
    return 'Unable to open $what picker.\n\nError: ${result.errorDetails}';
  }
  return 'Unable to open $what picker.';
}
