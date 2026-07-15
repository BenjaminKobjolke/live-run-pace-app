import 'dart:convert';

import 'package:file_picker/file_picker.dart';

import '../models/app_settings.dart';
import '../models/distance_history.dart';
import '../models/run_screen_layout.dart';
import '../models/settings_transfer_result.dart';
import '../models/tts_settings.dart';
import 'app_logger.dart';
import 'storage_permission.dart';
import 'storage_service.dart';

/// Exports all settings to a JSON file and imports them back. UI-free like
/// Mp3PickerService; callers map [SettingsTransferResult] to dialogs.
///
/// The envelope versions the whole file (`formatVersion`) and holds one
/// section per settings [StorageKeys] key. Run data (`active_session`,
/// `session_history`) is deliberately excluded — importing another device's
/// mid-run state would be dangerous. See docs/IMPORT_EXPORT.md.
class SettingsTransferService {
  static const int _formatVersion = 1;
  static const String _appId = 'live_run_pace_app';
  static const String _defaultFileName = 'live_run_pace_settings.json';

  final StorageService _storage;

  SettingsTransferService({StorageService? storage})
      : _storage = storage ?? StorageService.instance;

  /// Builds the export envelope from the current typed settings. Pure JSON
  /// building — file writing lives in [exportToFile].
  Future<String> buildExportJson() async {
    final settings = await _storage.loadSettings();
    final ttsSettings = await _storage.loadTtsSettings();
    final layouts = await _storage.loadScreenLayouts();
    final distanceHistory = await _storage.loadDistanceHistory();

    return jsonEncode({
      'formatVersion': _formatVersion,
      'app': _appId,
      'exportedAt': DateTime.now().toIso8601String(),
      'sections': {
        StorageKeys.appSettings: settings.toJson(),
        StorageKeys.ttsSettings: ttsSettings.toJson(),
        StorageKeys.screenLayouts: layouts.toJson(),
        StorageKeys.distanceHistory: distanceHistory.toJson(),
      },
    });
  }

  /// Parses [jsonText] and persists every known section it contains. Each
  /// section goes through its model's tolerant `fromJson`, so unknown fields
  /// (and unknown widget types) from newer app versions are handled there.
  /// Nothing is written when the file is invalid as a whole.
  Future<SettingsTransferResult> applyImportJson(String jsonText) async {
    Map<String, dynamic> envelope;
    try {
      envelope = jsonDecode(jsonText) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.e('Settings import: unparseable file', error: e);
      return const SettingsTransferResult(SettingsTransferStatus.invalidFile);
    }

    final version = envelope['formatVersion'];
    if (version is! int || version > _formatVersion) {
      return const SettingsTransferResult(
        SettingsTransferStatus.unsupportedVersion,
      );
    }

    final sections = envelope['sections'];
    if (sections is! Map<String, dynamic>) {
      return const SettingsTransferResult(SettingsTransferStatus.invalidFile);
    }

    final imported = <String>[];
    Future<void> section(
      String key,
      Future<void> Function(Map<String, dynamic> json) apply,
    ) async {
      final json = sections[key];
      if (json is! Map<String, dynamic>) return;
      try {
        await apply(json);
        imported.add(key);
      } catch (e) {
        AppLogger.e('Settings import: section $key failed', error: e);
      }
    }

    await section(StorageKeys.appSettings,
        (j) => _storage.saveSettings(AppSettings.fromJson(j)));
    await section(StorageKeys.ttsSettings,
        (j) => _storage.saveTtsSettings(TtsSettings.fromJson(j)));
    await section(StorageKeys.screenLayouts,
        (j) => _storage.saveScreenLayouts(RunScreenLayouts.fromJson(j)));
    await section(StorageKeys.distanceHistory,
        (j) => _storage.saveDistanceHistory(DistanceHistory.fromJson(j)));

    if (imported.isEmpty) {
      return const SettingsTransferResult(SettingsTransferStatus.invalidFile);
    }
    AppLogger.d('Settings import: restored ${imported.join(', ')}');
    return SettingsTransferResult(
      SettingsTransferStatus.imported,
      importedSections: imported,
    );
  }

  /// Opens a save dialog and writes the export. On Android/web the picker
  /// itself writes the passed [bytes] (SAF — no storage permission needed).
  Future<SettingsTransferResult> exportToFile() async {
    try {
      final json = await buildExportJson();
      // ponytail: no desktop path-write branch — app ships Android/web only.
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Export settings',
        fileName: _defaultFileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: utf8.encode(json),
      );
      if (path == null) {
        return const SettingsTransferResult(SettingsTransferStatus.cancelled);
      }
      // May be a content:// URI — report it, never reopen it with dart:io.
      return SettingsTransferResult(
        SettingsTransferStatus.exported,
        filePath: path,
      );
    } catch (e) {
      AppLogger.e('Settings export failed', error: e);
      return SettingsTransferResult(
        SettingsTransferStatus.error,
        errorDetails: e.toString(),
      );
    }
  }

  /// Opens a file picker, reads the chosen file and imports it.
  Future<SettingsTransferResult> importFromFile() async {
    try {
      final denied = await _requestLegacyPermission();
      if (denied != null) return denied;

      final result = await _pickJsonFile();
      final bytes =
          (result != null && result.files.isNotEmpty)
              ? result.files.first.bytes
              : null;
      if (bytes == null) {
        return const SettingsTransferResult(SettingsTransferStatus.cancelled);
      }
      return await applyImportJson(utf8.decode(bytes));
    } catch (e) {
      AppLogger.e('Settings import failed', error: e);
      return SettingsTransferResult(
        SettingsTransferStatus.error,
        errorDetails: e.toString(),
      );
    }
  }

  /// Android <= 12 file pickers still need the storage permission; newer
  /// versions use SAF and need none. Returns a failure result or null to
  /// proceed.
  Future<SettingsTransferResult?> _requestLegacyPermission() async {
    final sdkInt = await androidSdkInt();
    if (sdkInt == 0 || sdkInt >= 33) return null;

    final status = await (await storagePermissionForDevice()).request();
    if (status.isPermanentlyDenied) {
      return const SettingsTransferResult(
        SettingsTransferStatus.permissionPermanentlyDenied,
      );
    }
    if (status.isDenied) {
      return const SettingsTransferResult(
        SettingsTransferStatus.permissionDenied,
      );
    }
    return null;
  }

  /// JSON-filtered picker with the FileType.any fallback old Android needs
  /// (custom-extension filters are flaky there — same quirk as the MP3
  /// picker). `withData` avoids content-URI path problems.
  Future<FilePickerResult?> _pickJsonFile() async {
    try {
      return await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
    } catch (e) {
      AppLogger.d('JSON-filtered picker failed, falling back to any: $e');
      if (await androidSdkInt() <= 28) {
        return FilePicker.platform.pickFiles(
          type: FileType.any,
          withData: true,
        );
      }
      rethrow;
    }
  }
}
