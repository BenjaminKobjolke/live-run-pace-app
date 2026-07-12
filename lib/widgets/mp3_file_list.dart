import 'package:flutter/material.dart';

/// Scrollable list of selected MP3 file paths with per-item remove and a
/// Clear All action.
class Mp3FileList extends StatelessWidget {
  /// Absolute paths of the selected audio files.
  final List<String> filePaths;

  /// Whether remove/clear actions are enabled.
  final bool enabled;

  /// Called with the path to remove when its X is tapped.
  final ValueChanged<String> onRemove;

  /// Called when Clear All is tapped.
  final VoidCallback onClearAll;

  const Mp3FileList({
    super.key,
    required this.filePaths,
    required this.enabled,
    required this.onRemove,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 360),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white30),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: filePaths.length,
              itemBuilder: (context, index) {
                final filePath = filePaths[index];
                final fileName = filePath.split('/').last;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.music_note, color: Colors.white70, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          fileName,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: enabled ? () => onRemove(filePath) : null,
                        icon: const Icon(Icons.close, color: Colors.white, size: 16),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (filePaths.length > 1)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white30)),
              ),
              child: TextButton(
                onPressed: enabled ? onClearAll : null,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                ),
                child: const Text('Clear All', style: TextStyle(fontSize: 12)),
              ),
            ),
        ],
      ),
    );
  }
}
