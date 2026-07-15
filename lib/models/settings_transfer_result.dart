/// Outcome of a settings export or import (mirrors Mp3PickResult).
enum SettingsTransferStatus {
  /// Export written successfully.
  exported,

  /// Import parsed and persisted successfully.
  imported,

  /// The user dismissed the file dialog.
  cancelled,

  /// Storage permission denied (import on older Android).
  permissionDenied,

  /// Storage permission permanently denied — user must use app settings.
  permissionPermanentlyDenied,

  /// The file is not a settings export (bad JSON or no known sections).
  invalidFile,

  /// The file was written by a newer app version.
  unsupportedVersion,

  /// Unexpected failure; see [SettingsTransferResult.errorDetails].
  error,
}

/// Typed result of a settings transfer operation. UI maps this to dialogs.
class SettingsTransferResult {
  /// What happened.
  final SettingsTransferStatus status;

  /// Where the export was written, when known (may be a content:// URI).
  final String? filePath;

  /// Diagnostic details for [SettingsTransferStatus.error].
  final String? errorDetails;

  /// Storage keys of the sections an import actually restored.
  final List<String> importedSections;

  const SettingsTransferResult(
    this.status, {
    this.filePath,
    this.errorDetails,
    this.importedSections = const [],
  });
}
