import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/tts_settings.dart';
import '../services/mp3_picker_service.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/info_dialog.dart';
import '../widgets/mp3_file_list.dart';
import '../widgets/setting_controls.dart';

/// Settings screen for TTS, audio, and gesture options.
class SettingsScreen extends StatefulWidget {
  /// The settings to edit; a modified copy is returned via `Navigator.pop`.
  final TtsSettings currentSettings;

  const SettingsScreen({super.key, required this.currentSettings});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Mp3PickerService _picker = Mp3PickerService();

  late bool _enabled;
  late double _speed;
  late double _volume;
  late bool _pauseOtherAudio;
  List<String> _mp3FilePaths = [];
  late bool _resumeAimpAfterPlayback;
  late bool _touchToToggleAimp;
  late bool _doubleTapToCompleteKm;
  late bool _buttonNavigationDelay;
  late int _delayAfterAudioMs;

  @override
  void initState() {
    super.initState();
    final s = widget.currentSettings;
    _enabled = s.enabled;
    _speed = s.speed;
    _volume = s.volume;
    _pauseOtherAudio = s.pauseOtherAudio;
    _mp3FilePaths = List<String>.from(s.mp3FilePaths);
    _resumeAimpAfterPlayback = s.resumeAimpAfterPlayback;
    _touchToToggleAimp = s.touchToToggleAimp;
    _doubleTapToCompleteKm = s.doubleTapToCompleteKm;
    _buttonNavigationDelay = s.buttonNavigationDelay;
    _delayAfterAudioMs = s.delayAfterAudioMs;
  }

  Future<void> _pickFiles() async {
    final result = await _picker.pickFiles(_mp3FilePaths);
    if (!mounted) return;
    await _handlePickResult(result, isFolder: false);
  }

  Future<void> _pickFolder() async {
    final result = await _picker.pickFolder(_mp3FilePaths);
    if (!mounted) return;
    await _handlePickResult(result, isFolder: true);
  }

  Future<void> _handlePickResult(Mp3PickResult result, {required bool isFolder}) async {
    switch (result.status) {
      case Mp3PickStatus.added:
        if (result.paths.isNotEmpty) {
          setState(() => _mp3FilePaths.addAll(result.paths));
        }
        break;
      case Mp3PickStatus.cancelled:
        break;
      case Mp3PickStatus.permissionDenied:
        await showInfoDialog(context,
            title: 'Permission Required',
            message: 'Storage permission is required to select MP3 files. Please grant permission and try again.');
        break;
      case Mp3PickStatus.permissionPermanentlyDenied:
        final openSettings = await showConfirmDialog(context,
            title: 'Permission Denied',
            message: 'Storage permission has been permanently denied. Please enable it in app settings to select MP3 files.',
            confirmLabel: 'Settings');
        if (openSettings) openAppSettings();
        break;
      case Mp3PickStatus.emptyFolder:
        await showInfoDialog(context,
            title: 'No Audio Files Found',
            message: 'The selected folder does not contain any audio files (MP3, WAV, M4A).');
        break;
      case Mp3PickStatus.noNewFiles:
        await showInfoDialog(context,
            title: 'No New Files Added',
            message: 'All ${result.totalFound} audio files from the selected folder are already in your list.');
        break;
      case Mp3PickStatus.error:
        await showInfoDialog(context,
            title: isFolder ? 'Folder Selection Error' : 'File Selection Error',
            message: _pickerErrorMessage(result, isFolder: isFolder));
        break;
    }
  }

  String _pickerErrorMessage(Mp3PickResult result, {required bool isFolder}) {
    final what = isFolder ? 'folder' : 'file';
    if (result.androidVersion != 0 && result.androidVersion <= 28) {
      final alternative = isFolder
          ? 'You can also manually select individual files instead.'
          : 'You can also manually copy MP3 files to Downloads folder.';
      return '${isFolder ? 'Folder' : 'File'} picker issue on Android ${result.androidVersion}. Please try:\n\n'
          '1. Go to Android Settings → Apps → Live Run Pace → Permissions\n'
          '2. Enable "Storage" permission\n'
          '3. Restart the app and try again\n\n$alternative';
    }
    if (result.errorDetails != null) {
      return 'Unable to open $what picker.\n\nError: ${result.errorDetails}';
    }
    return 'Unable to open $what picker.';
  }

  void _save() {
    Navigator.of(context).pop(TtsSettings(
      enabled: _enabled,
      speed: _speed,
      volume: _volume,
      pauseOtherAudio: _pauseOtherAudio,
      mp3FilePaths: _mp3FilePaths,
      resumeAimpAfterPlayback: _resumeAimpAfterPlayback,
      touchToToggleAimp: _touchToToggleAimp,
      doubleTapToCompleteKm: _doubleTapToCompleteKm,
      buttonNavigationDelay: _buttonNavigationDelay,
      delayAfterAudioMs: _delayAfterAudioMs,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Settings'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SettingSwitch(
              label: 'TTS Enabled',
              value: _enabled,
              onChanged: (v) => setState(() => _enabled = v),
            ),
            const SizedBox(height: 20),
            SettingSlider(
              label: 'Speed: ${_speed.toStringAsFixed(1)}',
              value: _speed,
              min: 0.1,
              max: 1.0,
              divisions: 9,
              onChanged: _enabled ? (v) => setState(() => _speed = v) : null,
            ),
            const SizedBox(height: 20),
            SettingSlider(
              label: 'Volume: ${_volume.toStringAsFixed(1)}',
              value: _volume,
              min: 0.5,
              max: 2.0,
              divisions: 15,
              onChanged: _enabled ? (v) => setState(() => _volume = v) : null,
            ),
            const SizedBox(height: 20),
            SettingSlider(
              label: 'Delay after audio: $_delayAfterAudioMs ms',
              value: _delayAfterAudioMs.toDouble(),
              min: 0,
              max: 3000,
              divisions: 30,
              onChanged: _enabled ? (v) => setState(() => _delayAfterAudioMs = v.round()) : null,
            ),
            const SizedBox(height: 20),
            SettingSwitch(
              label: 'Pause other apps audio',
              value: _pauseOtherAudio,
              onChanged: _enabled ? (v) => setState(() => _pauseOtherAudio = v) : null,
            ),
            const SizedBox(height: 20),
            SettingSwitch(
              label: 'Resume AIMP after playback',
              value: _resumeAimpAfterPlayback,
              onChanged: _pauseOtherAudio ? (v) => setState(() => _resumeAimpAfterPlayback = v) : null,
            ),
            const SizedBox(height: 20),
            SettingSwitch(
              label: 'Touch main screen to play/pause AIMP',
              value: _touchToToggleAimp,
              onChanged: (v) => setState(() => _touchToToggleAimp = v),
            ),
            const SizedBox(height: 20),
            SettingSwitch(
              label: 'Double tap main screen to complete kilometer',
              value: _doubleTapToCompleteKm,
              onChanged: (v) => setState(() => _doubleTapToCompleteKm = v),
            ),
            const SizedBox(height: 20),
            SettingSwitch(
              label: 'Delay button navigation',
              value: _buttonNavigationDelay,
              onChanged: (v) => setState(() => _buttonNavigationDelay = v),
            ),
            const SizedBox(height: 20),
            _buildMp3Section(),
          ],
        ),
      ),
    );
  }

  Widget _buildMp3Section() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('MP3 Sound After TTS', style: TextStyle(color: Colors.white, fontSize: 16)),
            if (_mp3FilePaths.isNotEmpty)
              Text(
                '${_mp3FilePaths.length} file${_mp3FilePaths.length == 1 ? '' : 's'}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_mp3FilePaths.isNotEmpty) ...[
          Mp3FileList(
            filePaths: _mp3FilePaths,
            enabled: _enabled,
            onRemove: (path) => setState(() => _mp3FilePaths.remove(path)),
            onClearAll: () => setState(() => _mp3FilePaths.clear()),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Expanded(child: _addButton('Add Files', _enabled ? _pickFiles : null)),
            const SizedBox(width: 8),
            Expanded(child: _addButton('Add Folder', _enabled ? _pickFolder : null)),
          ],
        ),
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
