import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/app_settings.dart';
import '../models/running_session.dart';
import '../models/tts_settings.dart';
import '../services/storage_service.dart';
import 'start_screen.dart';
import 'completion_screen.dart';

class MainScreen extends StatefulWidget {
  final AppSettings settings;
  final TtsSettings ttsSettings;
  final RunningSession? existingSession;

  const MainScreen({
    super.key,
    required this.settings,
    required this.ttsSettings,
    this.existingSession,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  late RunningSession _session;
  Timer? _timer;
  Timer? _saveTimer;
  bool _showFlash = false;
  FlutterTts? _flutterTts;
  AudioPlayer? _audioPlayer;
  bool _isAppInBackground = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeSession();
    _initializeTts();
    _initializeAudioPlayer();
    _startTimers();
  }

  Future<void> _initializeTts() async {
    if (!widget.ttsSettings.enabled) {
      _flutterTts = null;
      return;
    }

    _flutterTts = FlutterTts();
    try {
      await _flutterTts!.setLanguage("en-US");
      await _flutterTts!.setSpeechRate(widget.ttsSettings.speed);
      await _flutterTts!.setVolume(widget.ttsSettings.volume);
      await _flutterTts!.setPitch(1.0);

      if (widget.ttsSettings.pauseOtherAudio) {
        // Configure audio session to pause music - Android and iOS
        await _flutterTts!.setSharedInstance(true);

        // iOS audio configuration
        try {
          await _flutterTts!.setIosAudioCategory(IosTextToSpeechAudioCategory.playback,
              [IosTextToSpeechAudioCategoryOptions.duckOthers]);
        } catch (e) {
          // iOS config failed, continue (we're probably on Android)
        }

        // Enhanced Android audio focus - pause music during TTS
        await _flutterTts!.awaitSpeakCompletion(true);
      }
    } catch (e) {
      // TTS initialization failed, continue without it
      _flutterTts = null;
    }
  }

  void _initializeAudioPlayer() {
    if (widget.ttsSettings.mp3FilePath != null) {
      _audioPlayer = AudioPlayer();

      // Set initial audio context to not interfere with other apps
      _audioPlayer!.setAudioContext(AudioContext(
        android: AudioContextAndroid(
          audioFocus: AndroidAudioFocus.none,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.ambient,
          options: {AVAudioSessionOptions.mixWithOthers},
        ),
      ));
    }
  }

  Future<void> _playMp3Sound() async {
    if (_audioPlayer != null && widget.ttsSettings.mp3FilePath != null) {
      try {
        // Configure audio session based on user settings
        if (widget.ttsSettings.pauseOtherAudio) {
          // Request temporary audio focus to pause other apps
          await _audioPlayer!.setAudioContext(AudioContext(
            android: AudioContextAndroid(
              isSpeakerphoneOn: false,
              stayAwake: false,
              contentType: AndroidContentType.sonification,
              usageType: AndroidUsageType.notificationEvent,
              audioFocus: AndroidAudioFocus.gainTransientMayDuck,
            ),
            iOS: AudioContextIOS(
              category: AVAudioSessionCategory.playback,
              options: {
                AVAudioSessionOptions.duckOthers,
                AVAudioSessionOptions.interruptSpokenAudioAndMixWithOthers,
              },
            ),
          ));
        } else {
          // Mix with other audio without interrupting
          await _audioPlayer!.setAudioContext(AudioContext(
            android: AudioContextAndroid(
              isSpeakerphoneOn: false,
              stayAwake: false,
              contentType: AndroidContentType.sonification,
              usageType: AndroidUsageType.notificationEvent,
              audioFocus: AndroidAudioFocus.none,
            ),
            iOS: AudioContextIOS(
              category: AVAudioSessionCategory.ambient,
              options: {AVAudioSessionOptions.mixWithOthers},
            ),
          ));
        }

        // Play the MP3 and wait for completion
        await _audioPlayer!.play(DeviceFileSource(widget.ttsSettings.mp3FilePath!));

        // If we paused other audio, wait for MP3 to finish then release focus
        if (widget.ttsSettings.pauseOtherAudio) {
          // Create a completer to wait for playback completion
          final completer = Completer<void>();
          late StreamSubscription subscription;

          subscription = _audioPlayer!.onPlayerComplete.listen((_) async {
            subscription.cancel();

            // Release audio focus to allow other apps to resume
            try {
              await _audioPlayer!.setAudioContext(AudioContext(
                android: AudioContextAndroid(
                  audioFocus: AndroidAudioFocus.none,
                ),
                iOS: AudioContextIOS(
                  category: AVAudioSessionCategory.ambient,
                  options: {AVAudioSessionOptions.mixWithOthers},
                ),
              ));
            } catch (e) {
              // Audio context cleanup failed, continue anyway
            }

            completer.complete();
          });

          // Wait for completion or timeout after 30 seconds
          await completer.future.timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              subscription.cancel();
              // Cleanup on timeout
              _audioPlayer!.setAudioContext(AudioContext(
                android: AudioContextAndroid(audioFocus: AndroidAudioFocus.none),
                iOS: AudioContextIOS(
                  category: AVAudioSessionCategory.ambient,
                  options: {AVAudioSessionOptions.mixWithOthers},
                ),
              ));
            },
          );
        }
      } catch (e) {
        // MP3 playback failed, continue anyway
      }
    }
  }

  void _initializeSession() {
    if (widget.existingSession != null) {
      _session = widget.existingSession!;
    } else {
      final targets = List.generate(
        widget.settings.distance.ceil(),
        (index) => KilometerTarget(kmNumber: index + 1),
      );

      _session = RunningSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        distance: widget.settings.distance,
        targetPace: widget.settings.targetPace,
        maxPace: widget.settings.maxPace,
        startTime: DateTime.now(),
        targets: targets,
      );

      _saveSession();
    }
  }

  void _startTimers() {
    if (!_isAppInBackground) {
      _timer = Timer.periodic(const Duration(seconds: 10), (_) {
        if (mounted && !_isAppInBackground) setState(() {});
      });

      _saveTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        if (!_isAppInBackground) _saveSession();
      });
    }
  }

  void _stopTimers() {
    _timer?.cancel();
    _timer = null;
    _saveTimer?.cancel();
    _saveTimer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _isAppInBackground = true;
        _stopTimers();
        _saveSession(); // Save before going to background
        break;
      case AppLifecycleState.resumed:
        _isAppInBackground = false;
        _startTimers(); // Restart timers when returning
        break;
      case AppLifecycleState.inactive:
        // App is transitioning, don't change timer state
        break;
      case AppLifecycleState.hidden:
        _isAppInBackground = true;
        _stopTimers();
        break;
    }
  }

  Future<void> _saveSession() async {
    await StorageService.instance.saveActiveSession(_session);
  }

  Future<void> _goToNextKm() async {
    // Trigger visual and haptic feedback
    await _triggerFeedback();

    if (_session.isLastKilometer) {
      _showFinishConfirmation();
      return;
    }

    final currentTime = _session.elapsedTime;
    final updatedTargets = List<KilometerTarget>.from(_session.targets);
    updatedTargets[_session.currentKm - 1] = updatedTargets[_session.currentKm - 1]
        .copyWith(
          completedAt: DateTime.now(),
          actualTime: currentTime,
        );

    setState(() {
      _session = _session.copyWith(
        targets: updatedTargets,
        currentKm: _session.currentKm + 1,
      );
    });

    _saveSession();
  }

  Future<void> _triggerFeedback() async {
    // Show white flash
    setState(() {
      _showFlash = true;
    });

    // Vibrate device
    try {
      if (await Vibration.hasVibrator() ?? false) {
        await Vibration.vibrate(duration: 200);
      }
    } catch (e) {
      // Vibration not available, continue without it
    }

    // Hide flash after short duration
    Timer(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          _showFlash = false;
        });
      }
    });

    // Start TTS announcement after flash (don't await it)
    _announceProgress();
  }

  Future<void> _announceProgress() async {
    if (_isAppInBackground) return;

    // If TTS is disabled but MP3 is available, just play the MP3
    if (_flutterTts == null) {
      await _playMp3Sound();
      return;
    }

    try {
      // Stop any current speech before starting new announcement
      await _flutterTts!.stop();

      String announcement;

      // The km we just completed when "GOT IT!" was pressed
      final justCompletedKm = _session.currentKm - 1;
      final nextTargetKm = _session.currentKm;

      if (_session.isLastKilometer) {
        // Final kilometer announcement
        final timeLeft = _session.timeLeftForCurrentKm;
        final absTime = timeLeft.abs();
        final minutes = absTime.inMinutes;
        final seconds = absTime.inSeconds % 60;
        announcement = "Final kilometer! You have $minutes minutes and $seconds seconds left to finish.";
      } else {
        // Regular progress announcement based on pace status
        final paceStatus = _session.paceStatus;
        final timeLeft = _session.timeLeftForCurrentKm;
        final absTime = timeLeft.abs();
        final minutes = absTime.inMinutes;
        final seconds = absTime.inSeconds % 60;

        switch (paceStatus) {
          case PaceStatus.onSchedule:
            announcement = "Kilometer $justCompletedKm completed in time! The next target is kilometer $nextTargetKm. You have $minutes minutes and $seconds seconds left to reach the next target.";
            break;
          case PaceStatus.behindSchedule:
            final maxPaceMinutes = _session.maxPace.inMinutes;
            final maxPaceSeconds = _session.maxPace.inSeconds % 60;
            announcement = "Kilometer $justCompletedKm completed. You're behind schedule. Run the next kilometer in $maxPaceMinutes minutes and $maxPaceSeconds seconds to catch up.";
            break;
          case PaceStatus.aheadOfSchedule:
            announcement = "Kilometer $justCompletedKm completed. Slow down! You have $minutes minutes and $seconds seconds left to reach the next target!";
            break;
        }
      }

      // Add delay to ensure audio focus is acquired (only if pause other audio is enabled)
      if (widget.ttsSettings.pauseOtherAudio) {
        await Future.delayed(const Duration(milliseconds: 250));
        await _flutterTts!.awaitSpeakCompletion(true);
      }

      try {
        // First attempt to speak
        await _flutterTts!.speak(announcement);

        // Play MP3 sound after TTS completes
        await _playMp3Sound();
      } catch (e) {
        // If first attempt fails, try again after brief delay
        await Future.delayed(const Duration(milliseconds: 100));
        try {
          await _flutterTts!.speak(announcement);
          // Play MP3 sound after retry TTS completes
          await _playMp3Sound();
        } catch (e2) {
          // Both TTS attempts failed, still try to play MP3
          await _playMp3Sound();
        }
      }
    } catch (e) {
      // TTS failed, continue without announcement
    }
  }

  void _goToPreviousKm() {
    if (_session.currentKm > 1) {
      final updatedTargets = List<KilometerTarget>.from(_session.targets);
      updatedTargets[_session.currentKm - 1] = updatedTargets[_session.currentKm - 1]
          .copyWith(
            completedAt: null,
            actualTime: null,
          );

      setState(() {
        _session = _session.copyWith(
          targets: updatedTargets,
          currentKm: _session.currentKm - 1,
        );
      });

      _saveSession();
    }
  }

  void _showFinishConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF333333),
        title: const Text(
          'Finish Session?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to finish this running session?',
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
              _finishSession();
            },
            child: const Text('Finish', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _finishSession() {
    final currentTime = _session.elapsedTime;
    final updatedTargets = List<KilometerTarget>.from(_session.targets);
    updatedTargets[_session.currentKm - 1] = updatedTargets[_session.currentKm - 1]
        .copyWith(
          completedAt: DateTime.now(),
          actualTime: currentTime,
        );

    final completedSession = _session.copyWith(
      targets: updatedTargets,
      isCompleted: true,
    );

    StorageService.instance.saveSessionToHistory(completedSession);
    StorageService.instance.clearActiveSession();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => CompletionScreen(session: completedSession),
      ),
    );
  }

  void _showAbortConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF333333),
        title: const Text(
          'Abort Session?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to abort this running session? All progress will be lost.',
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
              _abortSession();
            },
            child: const Text('Abort', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _abortSession() {
    StorageService.instance.clearActiveSession();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const StartScreen()),
    );
  }

  @override
  void dispose() {
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);

    // Stop and cleanup timers
    _stopTimers();

    // Stop and cleanup TTS
    _cleanupTts();

    // Cleanup audio player
    _cleanupAudioPlayer();

    super.dispose();
  }

  Future<void> _cleanupTts() async {
    if (_flutterTts != null) {
      try {
        await _flutterTts!.stop();
        await _flutterTts!.awaitSpeakCompletion(true);
      } catch (e) {
        // TTS cleanup failed, continue anyway
      } finally {
        _flutterTts = null;
      }
    }
  }

  Future<void> _cleanupAudioPlayer() async {
    if (_audioPlayer != null) {
      try {
        // Stop any playing audio
        await _audioPlayer!.stop();

        // Release audio focus before disposing
        await _audioPlayer!.setAudioContext(AudioContext(
          android: AudioContextAndroid(
            audioFocus: AndroidAudioFocus.none,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
            options: {AVAudioSessionOptions.mixWithOthers},
          ),
        ));

        // Dispose the player
        await _audioPlayer!.dispose();
      } catch (e) {
        // Audio player cleanup failed, continue anyway
      } finally {
        _audioPlayer = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 20),
                  const Text(
                    'Next target distance',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  GestureDetector(
                    onTap: _showAbortConfirmation,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.black,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Text(
                '${_session.currentKm} km',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      const Text(
                        'Current',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _session.currentTimeDisplay,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Text(
                        'Next target',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _session.nextTargetTimeDisplay,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              const Text(
                'Time left',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),

              Text(
                _session.timeLeftDisplay,
                style: TextStyle(
                  color: _session.isOverTime ? Colors.red : Colors.green,
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Finish time',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),

              Text(
                _session.finishTimeDisplay,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const Spacer(),

              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: ElevatedButton(
                      onPressed: _session.currentKm > 1 ? _goToPreviousKm : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Icon(Icons.arrow_back, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: ElevatedButton(
                      onPressed: _goToNextKm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text(
                        'GOT IT!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        // White flash overlay
        if (_showFlash)
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.white,
          ),
      ],
    ),
  );
  }
}