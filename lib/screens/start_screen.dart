import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../models/tts_settings.dart';
import '../services/storage_service.dart';
import '../utils/distance_format.dart';
import '../widgets/start_screen_sections.dart';
import 'distance_input_screen.dart';
import 'pace_input_screen.dart';
import 'main_screen.dart';
import 'settings_screen.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  AppSettings _settings = const AppSettings();
  TtsSettings _ttsSettings = const TtsSettings();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await StorageService.instance.loadSettings();
    final ttsSettings = await StorageService.instance.loadTtsSettings();
    setState(() {
      _settings = settings;
      _ttsSettings = ttsSettings;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    await StorageService.instance.saveSettings(_settings);
  }

  Future<void> _saveTtsSettings() async {
    await StorageService.instance.saveTtsSettings(_ttsSettings);
  }

  Future<void> _showTtsSettingsDialog() async {
    final newSettings = await Navigator.of(context).push<TtsSettings>(
      MaterialPageRoute(
        builder: (context) => SettingsScreen(currentSettings: _ttsSettings),
      ),
    );

    if (newSettings != null) {
      // A settings import may also have replaced the app settings — reload
      // them so distance/paces reflect the imported values.
      final settings = await StorageService.instance.loadSettings();
      setState(() {
        _ttsSettings = newSettings;
        _settings = settings;
      });
      await _saveTtsSettings();
    }
  }

  Future<void> _showDistanceDialog() async {
    final newDistance = await Navigator.of(context).push<double>(
      MaterialPageRoute(
        builder: (context) =>
            DistanceInputScreen(currentDistance: _settings.distance),
      ),
    );

    if (newDistance != null) {
      setState(() {
        _settings = _settings.copyWith(distance: newDistance);
      });
      await _saveSettings();
    }
  }

  Future<void> _showTargetPaceDialog() async {
    final newPace = await Navigator.of(context).push<Duration>(
      MaterialPageRoute(
        builder: (context) => PaceInputScreen(
          currentPace: _settings.targetPace,
          title: 'Target Pace',
        ),
      ),
    );

    if (newPace != null) {
      setState(() {
        _settings = _settings.copyWith(
          paceMinutes: newPace.inMinutes,
          paceSeconds: newPace.inSeconds % 60,
        );
      });
      await _saveSettings();
    }
  }

  Future<void> _showMaxPaceDialog() async {
    final newPace = await Navigator.of(context).push<Duration>(
      MaterialPageRoute(
        builder: (context) =>
            PaceInputScreen(currentPace: _settings.maxPace, title: 'Max Pace'),
      ),
    );

    if (newPace != null) {
      setState(() {
        _settings = _settings.copyWith(
          maxPaceMinutes: newPace.inMinutes,
          maxPaceSeconds: newPace.inSeconds % 60,
        );
      });
      await _saveSettings();
    }
  }

  Future<void> _startSession() async {
    final layouts = await StorageService.instance.loadScreenLayouts();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => MainScreen(
          settings: _settings,
          ttsSettings: _ttsSettings,
          layouts: layouts,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DistanceSettingsRow(
                distanceText: '${formatDistance(_settings.distance)} km',
                onDistanceTap: _showDistanceDialog,
                onSettingsTap: _showTtsSettingsDialog,
              ),
              const SizedBox(height: 32),
              PacesSection(
                targetText: _settings.paceDisplay,
                maxText: _settings.maxPaceDisplay,
                onTargetTap: _showTargetPaceDialog,
                onMaxTap: _showMaxPaceDialog,
              ),
              const SizedBox(height: 40),
              Text(
                'Finish time:',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _settings.finishTimeDisplay,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              StartButton(onPressed: _startSession),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
