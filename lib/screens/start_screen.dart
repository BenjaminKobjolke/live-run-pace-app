import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../models/tts_settings.dart';
import '../services/storage_service.dart';
import '../widgets/distance_dialog.dart';
import '../widgets/pace_dialog.dart';
import '../widgets/tts_settings_dialog.dart';
import 'main_screen.dart';

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
    final newSettings = await showDialog<TtsSettings>(
      context: context,
      builder: (context) => TtsSettingsDialog(currentSettings: _ttsSettings),
    );

    if (newSettings != null) {
      setState(() {
        _ttsSettings = newSettings;
      });
      await _saveTtsSettings();
    }
  }

  Future<void> _showDistanceDialog() async {
    final newDistance = await showDialog<double>(
      context: context,
      builder: (context) => DistanceDialog(currentDistance: _settings.distance),
    );

    if (newDistance != null) {
      setState(() {
        _settings = _settings.copyWith(distance: newDistance);
      });
      await _saveSettings();
    }
  }

  Future<void> _showTargetPaceDialog() async {
    final newPace = await showDialog<Duration>(
      context: context,
      builder: (context) => PaceDialog(currentPace: _settings.targetPace),
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
    final newPace = await showDialog<Duration>(
      context: context,
      builder: (context) => PaceDialog(currentPace: _settings.maxPace),
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

  void _startSession() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => MainScreen(
          settings: _settings,
          ttsSettings: _ttsSettings,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
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
              // Settings button at top
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: _showTtsSettingsDialog,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.settings,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              const Text(
                'Distance',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 8),

              GestureDetector(
                onTap: _showDistanceDialog,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${_settings.distance.toStringAsFixed(3)} km',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              const Text(
                'Paces',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'Target',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: _showTargetPaceDialog,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white, width: 2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _settings.paceDisplay,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'Max',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: _showMaxPaceDialog,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white, width: 2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _settings.maxPaceDisplay,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _startSession,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text(
                    'START',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}