import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/tts_settings.dart';

class TtsSettingsDialog extends StatefulWidget {
  final TtsSettings currentSettings;

  const TtsSettingsDialog({
    super.key,
    required this.currentSettings,
  });

  @override
  State<TtsSettingsDialog> createState() => _TtsSettingsDialogState();
}

class _TtsSettingsDialogState extends State<TtsSettingsDialog> {
  late bool _enabled;
  late double _speed;
  late double _volume;
  late bool _pauseOtherAudio;
  String? _mp3FilePath;

  @override
  void initState() {
    super.initState();
    _enabled = widget.currentSettings.enabled;
    _speed = widget.currentSettings.speed;
    _volume = widget.currentSettings.volume;
    _pauseOtherAudio = widget.currentSettings.pauseOtherAudio;
    _mp3FilePath = widget.currentSettings.mp3FilePath;
  }

  Future<void> _pickMp3File() async {
    try {
      // Check and request permissions
      final permission = await _getStoragePermission();
      final status = await permission.request();

      if (status.isDenied) {
        _showPermissionDeniedDialog();
        return;
      }

      if (status.isPermanentlyDenied) {
        _showPermissionPermanentlyDeniedDialog();
        return;
      }

      // Permission granted, proceed with file picker
      // Try a more permissive approach first
      FilePickerResult? result;

      try {
        // Try with audio type first
        result = await FilePicker.platform.pickFiles(
          type: FileType.audio,
          allowMultiple: false,
        );
      } catch (audioError) {
        print('Audio file picker failed: $audioError, trying custom...');

        // Fallback to custom with mp3 extension
        try {
          result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['mp3'],
            allowMultiple: false,
          );
        } catch (customError) {
          print('Custom file picker failed: $customError, trying any...');

          // Final fallback to any file type
          result = await FilePicker.platform.pickFiles(
            type: FileType.any,
            allowMultiple: false,
          );
        }
      }

      if (result != null && result.files.isNotEmpty && result.files.single.path != null) {
        final selectedFile = result.files.single;
        if (selectedFile.path != null) {
          setState(() {
            _mp3FilePath = selectedFile.path!;
          });
        }
      }
    } catch (e) {
      // File picker error, show user-friendly message
      print('File picker error: $e'); // Debug logging
      _showFilePickerErrorDialog(e.toString());
    }
  }

  Permission _getStoragePermission() {
    // Use appropriate permission based on Android version
    // For Android 13+ (API 33+), use audio permission for MP3 files
    // For Android 12 and below, use storage permission
    try {
      return Permission.audio; // Try audio permission first (Android 13+)
    } catch (e) {
      return Permission.storage; // Fallback to storage permission (Android 12 and below)
    }
  }

  void _clearMp3File() {
    setState(() {
      _mp3FilePath = null;
    });
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF333333),
        title: const Text(
          'Permission Required',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Storage permission is required to select MP3 files. Please grant permission and try again.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPermissionPermanentlyDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF333333),
        title: const Text(
          'Permission Denied',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Storage permission has been permanently denied. Please enable it in app settings to select MP3 files.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Settings', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showFilePickerErrorDialog([String? errorDetails]) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF333333),
        title: const Text(
          'File Selection Error',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          errorDetails != null
            ? 'Unable to open file picker.\n\nError: $errorDetails'
            : 'Unable to open file picker. Please try again or check if the file exists.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF333333),
      title: const Text(
        'TTS Settings',
        style: TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // TTS On/Off
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TTS Enabled',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                Switch(
                  value: _enabled,
                  onChanged: (value) => setState(() => _enabled = value),
                  activeColor: Colors.white,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // TTS Speed
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Speed: ${_speed.toStringAsFixed(1)}',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                Slider(
                  value: _speed,
                  min: 0.1,
                  max: 1.0,
                  divisions: 9,
                  onChanged: _enabled ? (value) => setState(() => _speed = value) : null,
                  activeColor: Colors.white,
                  inactiveColor: Colors.white30,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // TTS Volume
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Volume: ${_volume.toStringAsFixed(1)}',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                Slider(
                  value: _volume,
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  onChanged: _enabled ? (value) => setState(() => _volume = value) : null,
                  activeColor: Colors.white,
                  inactiveColor: Colors.white30,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Pause Other Apps Audio
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Pause other apps audio',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                Switch(
                  value: _pauseOtherAudio,
                  onChanged: _enabled ? (value) => setState(() => _pauseOtherAudio = value) : null,
                  activeColor: Colors.white,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // MP3 File Selection
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MP3 Sound After TTS',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 8),
                if (_mp3FilePath != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white30),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.music_note, color: Colors.white70, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _mp3FilePath!.split('/').last,
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: _enabled ? _clearMp3File : null,
                          icon: const Icon(Icons.close, color: Colors.white, size: 16),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _enabled ? _pickMp3File : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white, width: 1),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: Text(_mp3FilePath == null ? 'Select MP3' : 'Change MP3'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
        ),
        TextButton(
          onPressed: () {
            final newSettings = TtsSettings(
              enabled: _enabled,
              speed: _speed,
              volume: _volume,
              pauseOtherAudio: _pauseOtherAudio,
              mp3FilePath: _mp3FilePath,
            );
            Navigator.of(context).pop(newSettings);
          },
          child: const Text('Save', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}