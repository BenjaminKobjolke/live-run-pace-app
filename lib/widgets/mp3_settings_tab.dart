import 'package:flutter/material.dart';
import 'mp3_file_list.dart';

/// MP3 tab body: header, the selected-files list (with preview playback), and
/// the Add Files / Add Folder pickers. Picking logic stays in the settings
/// screen and is injected via [onPickFiles] / [onPickFolder].
class Mp3SettingsTab extends StatelessWidget {
  /// Absolute paths of the selected audio files.
  final List<String> filePaths;

  /// Whether the controls are enabled (mirrors the TTS master toggle).
  final bool enabled;

  /// Removes a single path from the list.
  final ValueChanged<String> onRemove;

  /// Clears the whole list.
  final VoidCallback onClearAll;

  /// Opens the multi-file picker.
  final VoidCallback onPickFiles;

  /// Opens the folder picker.
  final VoidCallback onPickFolder;

  /// Re-scans the last-picked folder. Null when no folder is remembered yet
  /// (hides the Refresh button).
  final VoidCallback? onRefreshFolder;

  const Mp3SettingsTab({
    super.key,
    required this.filePaths,
    required this.enabled,
    required this.onRemove,
    required this.onClearAll,
    required this.onPickFiles,
    required this.onPickFolder,
    required this.onRefreshFolder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'MP3 Sound After TTS',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            if (filePaths.isNotEmpty)
              Text(
                '${filePaths.length} file${filePaths.length == 1 ? '' : 's'}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (filePaths.isNotEmpty) ...[
          Mp3FileList(
            filePaths: filePaths,
            enabled: enabled,
            onRemove: onRemove,
            onClearAll: onClearAll,
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Expanded(
              child: _addButton('Add Files', enabled ? onPickFiles : null),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _addButton('Add Folder', enabled ? onPickFolder : null),
            ),
          ],
        ),
        if (onRefreshFolder != null) ...[
          const SizedBox(height: 8),
          _addButton('Refresh Folder', enabled ? onRefreshFolder : null),
        ],
      ],
    );
  }

  Widget _addButton(String label, VoidCallback? onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white, width: 1),
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
      child: Text(label),
    );
  }
}
