import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
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
  List<String> _mp3FilePaths = [];
  late bool _resumeAimpAfterPlayback;
  late bool _touchToToggleAimp;
  late bool _doubleTapToCompleteKm;

  @override
  void initState() {
    super.initState();
    _enabled = widget.currentSettings.enabled;
    _speed = widget.currentSettings.speed;
    _volume = widget.currentSettings.volume;
    _pauseOtherAudio = widget.currentSettings.pauseOtherAudio;
    _mp3FilePaths = List<String>.from(widget.currentSettings.mp3FilePaths);
    _resumeAimpAfterPlayback = widget.currentSettings.resumeAimpAfterPlayback;
    _touchToToggleAimp = widget.currentSettings.touchToToggleAimp;
    _doubleTapToCompleteKm = widget.currentSettings.doubleTapToCompleteKm;
  }

  Future<void> _pickMp3File() async {
    // Get Android version for debugging
    int androidVersion = 0;
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      androidVersion = androidInfo.version.sdkInt;
      print('Android SDK version: $androidVersion');
    }

    try {

      // Check and request permissions
      final permission = await _getStoragePermission();
      print('Using permission: $permission');
      final status = await permission.request();
      print('Permission status: $status');

      if (status.isDenied) {
        _showPermissionDeniedDialog();
        return;
      }

      if (status.isPermanentlyDenied) {
        _showPermissionPermanentlyDeniedDialog();
        return;
      }

      // Permission granted, proceed with file picker
      // Try different approaches based on Android version
      FilePickerResult? result;

      if (androidVersion >= 30) {
        // Android 11+ - try audio type first
        try {
          print('Trying audio file picker for Android $androidVersion...');
          result = await FilePicker.platform.pickFiles(
            type: FileType.audio,
            allowMultiple: true,
          );
        } catch (audioError) {
          print('Audio file picker failed: $audioError');
          result = null;
        }
      }

      // Fallback approaches for older Android or if audio picker failed
      if (result == null) {
        try {
          print('Trying custom MP3 file picker...');
          result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['mp3', 'wav', 'm4a'],
            allowMultiple: true,
          );
        } catch (customError) {
          print('Custom file picker failed: $customError');

          // Android 8-specific fallback
          if (androidVersion <= 28) {
            try {
              print('Trying any file type for Android $androidVersion...');
              result = await FilePicker.platform.pickFiles(
                type: FileType.any,
                allowMultiple: true,
              );
            } catch (anyError) {
              print('Any file picker failed: $anyError');
              throw Exception('All file picker methods failed on Android $androidVersion');
            }
          } else {
            throw customError;
          }
        }
      }

      if (result != null && result.files.isNotEmpty) {
        final newPaths = result.files
            .where((file) => file.path != null)
            .map((file) => file.path!)
            .where((path) => !_mp3FilePaths.contains(path)) // Avoid duplicates
            .toList();

        if (newPaths.isNotEmpty) {
          setState(() {
            _mp3FilePaths.addAll(newPaths);
          });
        }
      }
    } catch (e) {
      // File picker error, show user-friendly message
      print('File picker error: $e'); // Debug logging
      _showFilePickerErrorDialog(e.toString(), androidVersion);
    }
  }

  Future<void> _pickMp3Folder() async {
    // Get Android version for debugging
    int androidVersion = 0;
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      androidVersion = androidInfo.version.sdkInt;
      print('Android SDK version: $androidVersion');
    }

    try {
      // Check and request permissions
      final permission = await _getStoragePermission();
      print('Using permission: $permission');
      final status = await permission.request();
      print('Permission status: $status');

      if (status.isDenied) {
        _showPermissionDeniedDialog();
        return;
      }

      if (status.isPermanentlyDenied) {
        _showPermissionPermanentlyDeniedDialog();
        return;
      }

      // Permission granted, proceed with folder picker
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory != null) {
        print('Selected directory: $selectedDirectory');

        // Get all audio files from the selected directory
        final audioFiles = await _getAudioFilesFromDirectory(selectedDirectory);

        if (audioFiles.isEmpty) {
          _showEmptyFolderDialog();
          return;
        }

        // Filter out duplicates
        final newPaths = audioFiles
            .where((path) => !_mp3FilePaths.contains(path))
            .toList();

        if (newPaths.isNotEmpty) {
          setState(() {
            _mp3FilePaths.addAll(newPaths);
          });
          print('Added ${newPaths.length} audio files from folder');
        } else {
          _showNoDuplicatesDialog(audioFiles.length);
        }
      }
    } catch (e) {
      print('Folder picker error: $e');
      _showFolderPickerErrorDialog(e.toString(), androidVersion);
    }
  }

  Future<List<String>> _getAudioFilesFromDirectory(String dirPath) async {
    final dir = Directory(dirPath);
    final audioExtensions = ['mp3', 'wav', 'm4a'];
    final audioFiles = <String>[];

    try {
      await for (var entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final extension = entity.path.split('.').last.toLowerCase();
          if (audioExtensions.contains(extension)) {
            audioFiles.add(entity.path);
          }
        }
      }
    } catch (e) {
      print('Error scanning directory: $e');
    }

    return audioFiles;
  }

  Future<Permission> _getStoragePermission() async {
    // Use appropriate permission based on Android version
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      if (sdkInt >= 33) {
        // Android 13+ (API 33+) - use granular media permissions
        print('Using Permission.audio for Android $sdkInt');
        return Permission.audio;
      } else {
        // Android 12 and below - use storage permission
        print('Using Permission.storage for Android $sdkInt');
        return Permission.storage;
      }
    } else {
      // Non-Android platforms
      return Permission.storage;
    }
  }

  void _removeMp3File(String filePath) {
    setState(() {
      _mp3FilePaths.remove(filePath);
    });
  }

  void _clearAllMp3Files() {
    setState(() {
      _mp3FilePaths.clear();
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

  void _showFilePickerErrorDialog([String? errorDetails, int? androidVersion]) {
    String message = 'Unable to open file picker.';

    if (androidVersion != null && androidVersion <= 28) {
      message = 'File picker issue on Android $androidVersion. Please try:\n\n'
          '1. Go to Android Settings → Apps → Live Run Pace → Permissions\n'
          '2. Enable "Storage" permission\n'
          '3. Restart the app and try again\n\n'
          'You can also manually copy MP3 files to Downloads folder.';
    } else if (errorDetails != null) {
      message = 'Unable to open file picker.\n\nError: $errorDetails';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF333333),
        title: const Text(
          'File Selection Error',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          message,
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

  void _showEmptyFolderDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF333333),
        title: const Text(
          'No Audio Files Found',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'The selected folder does not contain any audio files (MP3, WAV, M4A).',
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

  void _showNoDuplicatesDialog(int totalFiles) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF333333),
        title: const Text(
          'No New Files Added',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'All $totalFiles audio files from the selected folder are already in your list.',
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

  void _showFolderPickerErrorDialog([String? errorDetails, int? androidVersion]) {
    String message = 'Unable to open folder picker.';

    if (androidVersion != null && androidVersion <= 28) {
      message = 'Folder picker issue on Android $androidVersion. Please try:\\n\\n'
          '1. Go to Android Settings → Apps → Live Run Pace → Permissions\\n'
          '2. Enable \"Storage\" permission\\n'
          '3. Restart the app and try again\\n\\n'
          'You can also manually select individual files instead.';
    } else if (errorDetails != null) {
      message = 'Unable to open folder picker.\\n\\nError: $errorDetails';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF333333),
        title: const Text(
          'Folder Selection Error',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          message,
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

            // Resume AIMP After Playback
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Resume AIMP after playback',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                Switch(
                  value: _resumeAimpAfterPlayback,
                  onChanged: _pauseOtherAudio ? (value) => setState(() => _resumeAimpAfterPlayback = value) : null,
                  activeColor: Colors.white,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Touch Main Screen to Play/Pause AIMP
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Touch main screen to play/pause AIMP',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                Switch(
                  value: _touchToToggleAimp,
                  onChanged: (value) => setState(() => _touchToToggleAimp = value),
                  activeColor: Colors.white,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Double Tap Main Screen to Complete Kilometer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Double tap main screen to complete kilometer',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                Switch(
                  value: _doubleTapToCompleteKm,
                  onChanged: (value) => setState(() => _doubleTapToCompleteKm = value),
                  activeColor: Colors.white,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // MP3 File Selection
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'MP3 Sound After TTS',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    if (_mp3FilePaths.isNotEmpty)
                      Text(
                        '${_mp3FilePaths.length} file${_mp3FilePaths.length == 1 ? '' : 's'}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_mp3FilePaths.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 360),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white30),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemCount: _mp3FilePaths.length,
                            itemBuilder: (context, index) {
                              final filePath = _mp3FilePaths[index];
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
                                      onPressed: _enabled ? () => _removeMp3File(filePath) : null,
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
                        if (_mp3FilePaths.length > 1)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              border: Border(top: BorderSide(color: Colors.white30)),
                            ),
                            child: TextButton(
                              onPressed: _enabled ? _clearAllMp3Files : null,
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(vertical: 4),
                              ),
                              child: const Text('Clear All', style: TextStyle(fontSize: 12)),
                            ),
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
                        child: const Text('Add Files'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _enabled ? _pickMp3Folder : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white, width: 1),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: const Text('Add Folder'),
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
              mp3FilePaths: _mp3FilePaths,
              resumeAimpAfterPlayback: _resumeAimpAfterPlayback,
              touchToToggleAimp: _touchToToggleAimp,
              doubleTapToCompleteKm: _doubleTapToCompleteKm,
            );
            Navigator.of(context).pop(newSettings);
          },
          child: const Text('Save', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}