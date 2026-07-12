import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

/// Scrollable list of selected MP3 file paths with per-item preview playback,
/// remove, and a Clear All action.
class Mp3FileList extends StatefulWidget {
  /// Absolute paths of the selected audio files.
  final List<String> filePaths;

  /// Whether preview/remove/clear actions are enabled.
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
  State<Mp3FileList> createState() => _Mp3FileListState();
}

class _Mp3FileListState extends State<Mp3FileList> {
  /// Single preview player shared by every row; only one file previews at a time.
  final AudioPlayer _player = AudioPlayer();

  /// Path currently previewing, or null when stopped.
  String? _playingPath;

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playingPath = null);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  /// Toggles preview for [filePath]: stops if it is already playing, otherwise
  /// stops any prior preview and starts this one.
  Future<void> _togglePreview(String filePath) async {
    if (_playingPath == filePath) {
      await _player.stop();
      if (mounted) setState(() => _playingPath = null);
      return;
    }
    await _player.stop();
    await _player.play(DeviceFileSource(filePath));
    if (mounted) setState(() => _playingPath = filePath);
  }

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
              itemCount: widget.filePaths.length,
              itemBuilder: (context, index) {
                final filePath = widget.filePaths[index];
                return _Mp3FileRow(
                  fileName: filePath.split('/').last,
                  isPlaying: _playingPath == filePath,
                  enabled: widget.enabled,
                  onToggle: () => _togglePreview(filePath),
                  onRemove: () => widget.onRemove(filePath),
                );
              },
            ),
          ),
          if (widget.filePaths.length > 1)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white30)),
              ),
              child: TextButton(
                onPressed: widget.enabled ? widget.onClearAll : null,
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

/// One selected-file row: preview toggle, file name, and remove button.
class _Mp3FileRow extends StatelessWidget {
  final String fileName;
  final bool isPlaying;
  final bool enabled;
  final VoidCallback onToggle;
  final VoidCallback onRemove;

  const _Mp3FileRow({
    required this.fileName,
    required this.isPlaying,
    required this.enabled,
    required this.onToggle,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: enabled ? onToggle : null,
            icon: Icon(
              isPlaying ? Icons.stop : Icons.play_arrow,
              color: Colors.white70,
              size: 18,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
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
            onPressed: enabled ? onRemove : null,
            icon: const Icon(Icons.close, color: Colors.white, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
