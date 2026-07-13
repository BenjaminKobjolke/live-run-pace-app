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
  /// Pick/scan status.
  final Mp3PickStatus status;

  /// Newly selected audio file paths.
  final List<String> paths;

  /// Total audio files found in a scanned folder (for empty/no-new messaging).
  final int totalFound;

  /// Error text when [status] is [Mp3PickStatus.error].
  final String? errorDetails;

  /// Detected Android SDK version (0 on non-Android), for version-specific hints.
  final int androidVersion;

  /// The folder that was picked/scanned, when this result came from a folder
  /// operation. Null for file picks and permission/error results. Callers
  /// persist this to enable a later "Refresh" re-scan.
  final String? folderPath;

  /// Creates an MP3 pick result.
  const Mp3PickResult(
    this.status, {
    this.paths = const [],
    this.totalFound = 0,
    this.errorDetails,
    this.androidVersion = 0,
    this.folderPath,
  });
}
