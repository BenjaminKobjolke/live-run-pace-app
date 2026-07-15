import 'package:flutter/material.dart';
import '../models/gesture_action.dart';
import '../models/mp3_pick_result.dart';
import '../models/tts_settings.dart';
import '../services/app_logger.dart';
import '../services/mp3_picker_service.dart';
import '../services/storage_service.dart';
import '../services/tts_speaker.dart';
import '../widgets/backup_settings_tab.dart';
import '../widgets/gesture_settings_tab.dart';
import '../widgets/mp3_pick_result_handler.dart';
import '../widgets/mp3_settings_tab.dart';
import '../widgets/screens_settings_tab.dart';
import '../widgets/tts_settings_tab.dart';

/// Settings screen for TTS, audio, gesture, run-screen and backup options.
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
  String? _mp3FolderPath;
  late bool _resumeAimpAfterPlayback;
  late GestureAction _singleTapAction;
  late GestureAction _doubleTapAction;
  late GestureAction _longPressAction;
  late bool _buttonNavigationDelay;
  late int _delayAfterAudioMs;

  /// True while a Test Voice preview is speaking (guards re-entrancy).
  bool _testing = false;

  @override
  void initState() {
    super.initState();
    final s = widget.currentSettings;
    _enabled = s.enabled;
    _speed = s.speed;
    _volume = s.volume;
    _pauseOtherAudio = s.pauseOtherAudio;
    _mp3FilePaths = List<String>.from(s.mp3FilePaths);
    _mp3FolderPath = s.mp3FolderPath;
    _resumeAimpAfterPlayback = s.resumeAimpAfterPlayback;
    _singleTapAction = s.singleTapAction;
    _doubleTapAction = s.doubleTapAction;
    _longPressAction = s.longPressAction;
    _buttonNavigationDelay = s.buttonNavigationDelay;
    _delayAfterAudioMs = s.delayAfterAudioMs;
  }

  /// Speaks a sample phrase at the current Speed/Volume slider values so the
  /// user can preview them before saving. Builds a throwaway [TtsSpeaker] with
  /// audio focus, AIMP resume, and MP3 disabled so it never disturbs other apps.
  Future<void> _testTts() async {
    if (_testing) return;
    setState(() => _testing = true);
    final probe = widget.currentSettings.copyWith(
      enabled: true,
      speed: _speed,
      volume: _volume,
      pauseOtherAudio: false,
      resumeAimpAfterPlayback: false,
      mp3FilePaths: const [],
    );
    final speaker = TtsSpeaker(probe);
    try {
      await speaker.init();
      await speaker.speak('Pace on target. Keep it up.');
    } catch (e) {
      AppLogger.e('TTS test failed', error: e);
    } finally {
      await speaker.dispose();
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _refreshFolder() async {
    final folder = _mp3FolderPath;
    if (folder == null) return;
    final result = await _picker.rescanFolder(folder, _mp3FilePaths);
    if (!mounted) return;
    await _handlePickResult(result, isFolder: true);
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

  Future<void> _handlePickResult(
    Mp3PickResult result, {
    required bool isFolder,
  }) async {
    // Remember the folder (from any folder op that reached it) so Refresh works.
    if (isFolder && result.folderPath != null) {
      _mp3FolderPath = result.folderPath;
    }
    if (result.status == Mp3PickStatus.added && result.paths.isNotEmpty) {
      setState(() => _mp3FilePaths.addAll(result.paths));
      return;
    }
    await showMp3PickResultDialogs(context, result, isFolder: isFolder);
  }

  /// A successful import replaced everything in storage; close the screen
  /// with the imported TTS settings so no stale draft can overwrite them.
  Future<void> _onImported() async {
    final imported = await StorageService.instance.loadTtsSettings();
    if (mounted) Navigator.of(context).pop(imported);
  }

  void _save() {
    Navigator.of(context).pop(
      TtsSettings(
        enabled: _enabled,
        speed: _speed,
        volume: _volume,
        pauseOtherAudio: _pauseOtherAudio,
        mp3FilePaths: _mp3FilePaths,
        mp3FolderPath: _mp3FolderPath,
        resumeAimpAfterPlayback: _resumeAimpAfterPlayback,
        singleTapAction: _singleTapAction,
        doubleTapAction: _doubleTapAction,
        longPressAction: _longPressAction,
        buttonNavigationDelay: _buttonNavigationDelay,
        delayAfterAudioMs: _delayAfterAudioMs,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
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
          bottom: const TabBar(
            isScrollable: true, // five tabs don't fit a 240px-wide screen
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: 'TTS'),
              Tab(text: 'Gestures'),
              Tab(text: 'MP3'),
              Tab(text: 'Screens'),
              Tab(text: 'Backup'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTtsTab(),
            _buildGesturesTab(),
            _buildMp3Tab(),
            const ScreensSettingsTab(),
            BackupSettingsTab(onImported: _onImported),
          ],
        ),
      ),
    );
  }

  Widget _buildTtsTab() {
    return TtsSettingsTab(
      enabled: _enabled,
      speed: _speed,
      volume: _volume,
      pauseOtherAudio: _pauseOtherAudio,
      resumeAimpAfterPlayback: _resumeAimpAfterPlayback,
      delayAfterAudioMs: _delayAfterAudioMs,
      testing: _testing,
      onEnabledChanged: (value) => setState(() => _enabled = value),
      onSpeedChanged: (value) => setState(() => _speed = value),
      onVolumeChanged: (value) => setState(() => _volume = value),
      onPauseOtherAudioChanged: (value) =>
          setState(() => _pauseOtherAudio = value),
      onResumeAimpAfterPlaybackChanged: (value) =>
          setState(() => _resumeAimpAfterPlayback = value),
      onDelayAfterAudioChanged: (value) =>
          setState(() => _delayAfterAudioMs = value),
      onTestVoice: _testTts,
    );
  }

  Widget _buildGesturesTab() {
    return GestureSettingsTab(
      singleTapAction: _singleTapAction,
      doubleTapAction: _doubleTapAction,
      longPressAction: _longPressAction,
      buttonNavigationDelay: _buttonNavigationDelay,
      onSingleTapChanged: (value) => setState(() => _singleTapAction = value),
      onDoubleTapChanged: (value) => setState(() => _doubleTapAction = value),
      onLongPressChanged: (value) => setState(() => _longPressAction = value),
      onButtonNavigationDelayChanged: (value) =>
          setState(() => _buttonNavigationDelay = value),
    );
  }

  Widget _buildMp3Tab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Mp3SettingsTab(
        filePaths: _mp3FilePaths,
        enabled: _enabled,
        onRemove: (path) => setState(() => _mp3FilePaths.remove(path)),
        onClearAll: () => setState(() => _mp3FilePaths.clear()),
        onPickFiles: _pickFiles,
        onPickFolder: _pickFolder,
        onRefreshFolder: _mp3FolderPath == null ? null : _refreshFolder,
      ),
    );
  }
}
