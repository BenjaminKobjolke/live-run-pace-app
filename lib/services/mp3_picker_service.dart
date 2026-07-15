import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../models/mp3_pick_result.dart';
import 'app_logger.dart';
import 'storage_permission.dart';

/// Picks and scans audio files, handling Android-version-specific permission
/// and file-picker quirks. UI-free so it can be tested and reused; callers map
/// the returned [Mp3PickResult] to dialogs.
class Mp3PickerService {
  static const _audioExtensions = ['mp3', 'wav', 'm4a'];

  /// Picks one or more audio files, skipping any already in [existingPaths].
  Future<Mp3PickResult> pickFiles(List<String> existingPaths) async {
    final androidVersion = await androidSdkInt();
    try {
      final permission = await storagePermissionForDevice(audio: true);
      AppLogger.d('Using permission: $permission');
      final status = await permission.request();
      AppLogger.d('Permission status: $status');

      if (status.isPermanentlyDenied) {
        return Mp3PickResult(
          Mp3PickStatus.permissionPermanentlyDenied,
          androidVersion: androidVersion,
        );
      }
      if (status.isDenied) {
        return Mp3PickResult(
          Mp3PickStatus.permissionDenied,
          androidVersion: androidVersion,
        );
      }

      final result = await _pickFilesForVersion(androidVersion);
      if (result == null || result.files.isEmpty) {
        return Mp3PickResult(
          Mp3PickStatus.cancelled,
          androidVersion: androidVersion,
        );
      }

      final newPaths = result.files
          .where((file) => file.path != null)
          .map((file) => file.path!)
          .where((path) => !existingPaths.contains(path))
          .toList();

      return Mp3PickResult(
        Mp3PickStatus.added,
        paths: newPaths,
        androidVersion: androidVersion,
      );
    } catch (e) {
      AppLogger.e('File picker error', error: e);
      return Mp3PickResult(
        Mp3PickStatus.error,
        errorDetails: e.toString(),
        androidVersion: androidVersion,
      );
    }
  }

  /// Picks a folder, recursively scans it for audio files, and returns those not
  /// already in [existingPaths].
  Future<Mp3PickResult> pickFolder(List<String> existingPaths) async {
    final androidVersion = await androidSdkInt();
    try {
      final permission = await storagePermissionForDevice(audio: true);
      AppLogger.d('Using permission: $permission');
      final status = await permission.request();
      AppLogger.d('Permission status: $status');

      if (status.isPermanentlyDenied) {
        return Mp3PickResult(
          Mp3PickStatus.permissionPermanentlyDenied,
          androidVersion: androidVersion,
        );
      }
      if (status.isDenied) {
        return Mp3PickResult(
          Mp3PickStatus.permissionDenied,
          androidVersion: androidVersion,
        );
      }

      final selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory == null) {
        return Mp3PickResult(
          Mp3PickStatus.cancelled,
          androidVersion: androidVersion,
        );
      }
      AppLogger.d('Selected directory: $selectedDirectory');

      return await _scanFolderResult(
        selectedDirectory,
        existingPaths,
        androidVersion,
      );
    } catch (e) {
      AppLogger.e('Folder picker error', error: e);
      return Mp3PickResult(
        Mp3PickStatus.error,
        errorDetails: e.toString(),
        androidVersion: androidVersion,
      );
    }
  }

  /// Re-scans an already-known [folderPath] (no picker dialog) and returns audio
  /// files not already in [existingPaths]. Used by the settings "Refresh"
  /// action to pick up files added to the folder after it was first selected.
  Future<Mp3PickResult> rescanFolder(
    String folderPath,
    List<String> existingPaths,
  ) async {
    final androidVersion = await androidSdkInt();
    try {
      final permission = await storagePermissionForDevice(audio: true);
      final status = await permission.request();
      if (status.isPermanentlyDenied) {
        return Mp3PickResult(
          Mp3PickStatus.permissionPermanentlyDenied,
          androidVersion: androidVersion,
        );
      }
      if (status.isDenied) {
        return Mp3PickResult(
          Mp3PickStatus.permissionDenied,
          androidVersion: androidVersion,
        );
      }

      return await _scanFolderResult(folderPath, existingPaths, androidVersion);
    } catch (e) {
      AppLogger.e('Folder rescan error', error: e);
      return Mp3PickResult(
        Mp3PickStatus.error,
        errorDetails: e.toString(),
        androidVersion: androidVersion,
        folderPath: folderPath,
      );
    }
  }

  /// Scans [directory] for audio files, dedups against [existingPaths], and maps
  /// the outcome to an [Mp3PickResult]. Shared by [pickFolder] and
  /// [rescanFolder]; always carries [folderPath] so callers can persist it.
  Future<Mp3PickResult> _scanFolderResult(
    String directory,
    List<String> existingPaths,
    int androidVersion,
  ) async {
    final audioFiles = await _getAudioFilesFromDirectory(directory);
    if (audioFiles.isEmpty) {
      return Mp3PickResult(
        Mp3PickStatus.emptyFolder,
        androidVersion: androidVersion,
        folderPath: directory,
      );
    }

    final newPaths = audioFiles
        .where((path) => !existingPaths.contains(path))
        .toList();
    if (newPaths.isEmpty) {
      return Mp3PickResult(
        Mp3PickStatus.noNewFiles,
        totalFound: audioFiles.length,
        androidVersion: androidVersion,
        folderPath: directory,
      );
    }

    AppLogger.d('Added ${newPaths.length} audio files from folder');
    return Mp3PickResult(
      Mp3PickStatus.added,
      paths: newPaths,
      androidVersion: androidVersion,
      folderPath: directory,
    );
  }

  Future<FilePickerResult?> _pickFilesForVersion(int androidVersion) async {
    FilePickerResult? result;

    if (androidVersion >= 30) {
      // Android 11+ - try the audio type first.
      try {
        AppLogger.d('Trying audio file picker for Android $androidVersion...');
        result = await FilePicker.platform.pickFiles(
          type: FileType.audio,
          allowMultiple: true,
        );
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
        return await FilePicker.platform.pickFiles(
          type: FileType.any,
          allowMultiple: true,
        );
      }
      rethrow;
    }
  }

  Future<List<String>> _getAudioFilesFromDirectory(String dirPath) async {
    final dir = Directory(dirPath);
    final audioFiles = <String>[];
    try {
      await for (final entity in dir.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is! File) continue;
        final extension = entity.path.split('.').last.toLowerCase();
        if (_audioExtensions.contains(extension)) {
          audioFiles.add(entity.path);
        }
      }
    } catch (e) {
      AppLogger.e('Error scanning directory', error: e);
    }
    return audioFiles;
  }
}
