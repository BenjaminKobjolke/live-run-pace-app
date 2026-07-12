import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'app_logger.dart';

/// Outcome of an MP3 pick/scan operation.
enum Mp3PickStatus {
  /// New files were selected (see [Mp3PickResult.paths]).
  added,

  /// User cancelled the picker; nothing to do.
  cancelled,

  /// Storage/audio permission was denied for this attempt.
  permissionDenied,

  /// Permission was permanently denied; user must enable it in app settings.
  permissionPermanentlyDenied,

  /// A folder was chosen but contained no audio files.
  emptyFolder,

  /// A folder was chosen but every audio file was already in the list.
  noNewFiles,

  /// The picker failed with an error (see [Mp3PickResult.errorDetails]).
  error,
}

/// Result of an MP3 pick/scan, including the selected [paths] and context for
/// user-facing messaging.
class Mp3PickResult {
  final Mp3PickStatus status;
  final List<String> paths;

  /// Total audio files found in a scanned folder (for empty/no-new messaging).
  final int totalFound;

  /// Error text when [status] is [Mp3PickStatus.error].
  final String? errorDetails;

  /// Detected Android SDK version (0 on non-Android), for version-specific hints.
  final int androidVersion;

  const Mp3PickResult(
    this.status, {
    this.paths = const [],
    this.totalFound = 0,
    this.errorDetails,
    this.androidVersion = 0,
  });
}

/// Picks and scans audio files, handling Android-version-specific permission
/// and file-picker quirks. UI-free so it can be tested and reused; callers map
/// the returned [Mp3PickResult] to dialogs.
class Mp3PickerService {
  static const _audioExtensions = ['mp3', 'wav', 'm4a'];

  /// Picks one or more audio files, skipping any already in [existingPaths].
  Future<Mp3PickResult> pickFiles(List<String> existingPaths) async {
    final androidVersion = await _androidVersion();
    try {
      final permission = await _getStoragePermission();
      AppLogger.d('Using permission: $permission');
      final status = await permission.request();
      AppLogger.d('Permission status: $status');

      if (status.isPermanentlyDenied) {
        return Mp3PickResult(Mp3PickStatus.permissionPermanentlyDenied, androidVersion: androidVersion);
      }
      if (status.isDenied) {
        return Mp3PickResult(Mp3PickStatus.permissionDenied, androidVersion: androidVersion);
      }

      final result = await _pickFilesForVersion(androidVersion);
      if (result == null || result.files.isEmpty) {
        return Mp3PickResult(Mp3PickStatus.cancelled, androidVersion: androidVersion);
      }

      final newPaths = result.files
          .where((file) => file.path != null)
          .map((file) => file.path!)
          .where((path) => !existingPaths.contains(path))
          .toList();

      return Mp3PickResult(Mp3PickStatus.added, paths: newPaths, androidVersion: androidVersion);
    } catch (e) {
      AppLogger.e('File picker error', error: e);
      return Mp3PickResult(Mp3PickStatus.error, errorDetails: e.toString(), androidVersion: androidVersion);
    }
  }

  /// Picks a folder, recursively scans it for audio files, and returns those not
  /// already in [existingPaths].
  Future<Mp3PickResult> pickFolder(List<String> existingPaths) async {
    final androidVersion = await _androidVersion();
    try {
      final permission = await _getStoragePermission();
      AppLogger.d('Using permission: $permission');
      final status = await permission.request();
      AppLogger.d('Permission status: $status');

      if (status.isPermanentlyDenied) {
        return Mp3PickResult(Mp3PickStatus.permissionPermanentlyDenied, androidVersion: androidVersion);
      }
      if (status.isDenied) {
        return Mp3PickResult(Mp3PickStatus.permissionDenied, androidVersion: androidVersion);
      }

      final selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory == null) {
        return Mp3PickResult(Mp3PickStatus.cancelled, androidVersion: androidVersion);
      }
      AppLogger.d('Selected directory: $selectedDirectory');

      final audioFiles = await _getAudioFilesFromDirectory(selectedDirectory);
      if (audioFiles.isEmpty) {
        return Mp3PickResult(Mp3PickStatus.emptyFolder, androidVersion: androidVersion);
      }

      final newPaths = audioFiles.where((path) => !existingPaths.contains(path)).toList();
      if (newPaths.isEmpty) {
        return Mp3PickResult(Mp3PickStatus.noNewFiles,
            totalFound: audioFiles.length, androidVersion: androidVersion);
      }

      AppLogger.d('Added ${newPaths.length} audio files from folder');
      return Mp3PickResult(Mp3PickStatus.added, paths: newPaths, androidVersion: androidVersion);
    } catch (e) {
      AppLogger.e('Folder picker error', error: e);
      return Mp3PickResult(Mp3PickStatus.error, errorDetails: e.toString(), androidVersion: androidVersion);
    }
  }

  Future<int> _androidVersion() async {
    if (!Platform.isAndroid) return 0;
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final v = androidInfo.version.sdkInt;
    AppLogger.d('Android SDK version: $v');
    return v;
  }

  Future<FilePickerResult?> _pickFilesForVersion(int androidVersion) async {
    FilePickerResult? result;

    if (androidVersion >= 30) {
      // Android 11+ - try the audio type first.
      try {
        AppLogger.d('Trying audio file picker for Android $androidVersion...');
        result = await FilePicker.platform.pickFiles(type: FileType.audio, allowMultiple: true);
      } catch (audioError) {
        AppLogger.d('Audio file picker failed: $audioError');
        result = null;
      }
    }

    if (result != null) return result;

    // Fallback: custom extensions (older Android or if audio picker failed).
    try {
      AppLogger.d('Trying custom MP3 file picker...');
      return await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _audioExtensions,
        allowMultiple: true,
      );
    } catch (customError) {
      AppLogger.d('Custom file picker failed: $customError');
      // Android 8-specific fallback: any file type.
      if (androidVersion <= 28) {
        AppLogger.d('Trying any file type for Android $androidVersion...');
        return await FilePicker.platform.pickFiles(type: FileType.any, allowMultiple: true);
      }
      rethrow;
    }
  }

  Future<List<String>> _getAudioFilesFromDirectory(String dirPath) async {
    final dir = Directory(dirPath);
    final audioFiles = <String>[];
    try {
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final extension = entity.path.split('.').last.toLowerCase();
          if (_audioExtensions.contains(extension)) {
            audioFiles.add(entity.path);
          }
        }
      }
    } catch (e) {
      AppLogger.e('Error scanning directory', error: e);
    }
    return audioFiles;
  }

  Future<Permission> _getStoragePermission() async {
    if (!Platform.isAndroid) return Permission.storage;
    final sdkInt = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
    if (sdkInt >= 33) {
      // Android 13+ (API 33+) - granular media permissions.
      AppLogger.d('Using Permission.audio for Android $sdkInt');
      return Permission.audio;
    }
    AppLogger.d('Using Permission.storage for Android $sdkInt');
    return Permission.storage;
  }
}
