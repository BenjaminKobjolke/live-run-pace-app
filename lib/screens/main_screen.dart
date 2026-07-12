import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import '../models/app_settings.dart';
import '../models/running_session.dart';
import '../models/tts_settings.dart';
import '../services/storage_service.dart';
import '../services/tts_speaker.dart';
import '../services/app_logger.dart';
import '../services/announcement_builder.dart';
import '../widgets/run_stats_view.dart';
import '../widgets/paused_overlay.dart';
import '../widgets/run_controls.dart';
import '../widgets/run_header.dart';
import '../widgets/confirm_dialog.dart';
import 'completion_screen.dart';
import 'home_screen.dart';

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

// ponytail: ~420 lines, over the 300 guideline. This is a cohesive real-time
// coordinator (session state + 3 timers + app-lifecycle + TTS lifecycle +
// gestures + navigation). Display chunks are already extracted to widgets
// (RunHeader/RunStatsView/RunControls/PausedOverlay) and announcement text to
// AnnouncementBuilder. Splitting the remaining logic cleanly needs a
// state-management layer (Cubit) the project intentionally does not use yet;
// upgrade path: introduce flutter_bloc and move the mutation/timer logic into a
// RunSessionCubit. Tracked as an accepted exception in CLAUDE.md.
class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  late RunningSession _session;
  Timer? _timer;
  Timer? _saveTimer;
  Timer? _buttonDelayTimer;
  bool _showFlash = false;
  bool _buttonsEnabled = true;
  bool _isPaused = false;
  TtsSpeaker? _ttsSpeaker;
  bool _isAppInBackground = false;
  static const MethodChannel _aimpChannel = MethodChannel('com.yourapp.live_run_pace/aimp');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeSession();
    _initializeTtsSpeaker();
    _startTimers();
  }

  Future<void> _initializeTtsSpeaker() async {
    _ttsSpeaker = TtsSpeaker(widget.ttsSettings);
    try {
      await _ttsSpeaker!.init();
    } catch (e) {
      AppLogger.e('TTS Speaker initialization failed', error: e);
      _ttsSpeaker = null;
    }
  }

  void _initializeSession() {
    if (widget.existingSession != null) {
      _session = widget.existingSession!;
      _isPaused = _session.isPaused; // recovered mid-pause -> reopen paused
      // Existing session - buttons are enabled immediately
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

      // New session - record distance to history and disable buttons temporarily
      _recordDistanceToHistory();
      _disableButtonsTemporarily();
    }
  }

  void _startTimers() {
    if (_isPaused) return; // frozen while paused
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
        _saveSession();
        break;
      case AppLifecycleState.resumed:
        _isAppInBackground = false;
        _startTimers();
        break;
      case AppLifecycleState.inactive:
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

  void _pauseSession() {
    _stopTimers();
    setState(() {
      _session = _session.copyWith(pausedAt: DateTime.now());
      _isPaused = true;
    });
    _saveSession();
    _ttsSpeaker?.speak('Session paused.'); // no-ops if TTS disabled in settings
  }

  void _continueSession() {
    // Shift startTime forward by the paused gap so elapsed time resumes exactly.
    final pausedGap = DateTime.now().difference(_session.pausedAt!);
    setState(() {
      _session = _session.copyWith(
        startTime: _session.startTime.add(pausedGap),
        clearPausedAt: true,
      );
      _isPaused = false;
    });
    _startTimers();
    _saveSession();
    _ttsSpeaker?.speak('Session resumed.'); // no-ops if TTS disabled in settings
  }

  void _disableButtonsTemporarily() {
    if (!widget.ttsSettings.buttonNavigationDelay) {
      return; // Feature disabled, keep buttons enabled
    }

    setState(() {
      _buttonsEnabled = false;
    });

    _buttonDelayTimer?.cancel();
    _buttonDelayTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _buttonsEnabled = true;
        });
      }
    });
  }

  Future<void> _recordDistanceToHistory() async {
    try {
      await StorageService.instance.addDistanceToHistory(_session.distance);
    } catch (e) {
      AppLogger.e('Error recording distance to history', error: e);
    }
  }

  Future<void> _goToNextKm() async {
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

    await _triggerFeedback();
    _saveSession();
    _disableButtonsTemporarily();
  }

  Future<void> _triggerFeedback() async {
    setState(() {
      _showFlash = true;
    });

    try {
      if (await Vibration.hasVibrator()) {
        await Vibration.vibrate(duration: 200);
      }
    } catch (e) {
      // Vibration not available
    }

    Timer(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          _showFlash = false;
        });
      }
    });

    _announceProgress();
  }

  Future<void> _announceProgress() async {
    if (_isAppInBackground) return;
    if (_ttsSpeaker == null) return;

    try {
      await _ttsSpeaker!.speak(AnnouncementBuilder.build(_session), playMp3: true);
    } catch (e) {
      AppLogger.e('Announcement error', error: e);
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
      _disableButtonsTemporarily();
    }
  }

  Future<void> _showFinishConfirmation() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Finish Session?',
      message: 'Are you sure you want to finish this running session?',
      confirmLabel: 'Finish',
    );
    if (ok) _finishSession();
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

  Future<void> _showAbortConfirmation() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Abort Session?',
      message: 'Are you sure you want to abort this running session? All progress will be lost.',
      confirmLabel: 'Abort',
      confirmColor: Colors.red,
    );
    if (ok) _abortSession();
  }

  void _abortSession() async {
    final abortedSession = _session.copyWith(
      isAborted: true,
    );

    await StorageService.instance.saveSessionToHistory(abortedSession);
    await StorageService.instance.clearActiveSession();

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  Future<void> _triggerAimpPlay() async {
    try {
      AppLogger.d('Screen tap detected, calling toggleAimp');
      AppLogger.d('Triggering AIMP toggle from screen tap');
      await _aimpChannel.invokeMethod('toggleAimp');
      AppLogger.d('AIMP toggle command sent');
    } catch (e) {
      AppLogger.e('Error triggering AIMP toggle', error: e);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopTimers();
    _buttonDelayTimer?.cancel();
    _cleanupTtsSpeaker();
    super.dispose();
  }

  Future<void> _cleanupTtsSpeaker() async {
    if (_ttsSpeaker != null) {
      try {
        await _ttsSpeaker!.dispose();
      } catch (e) {
        AppLogger.e('TTS Speaker cleanup failed', error: e);
      } finally {
        _ttsSpeaker = null;
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
                  RunHeader(onAbort: _showAbortConfirmation),

                  // Wrap the main content area in a GestureDetector for AIMP control and double tap
                  Expanded(
                    child: GestureDetector(
                      onTap: widget.ttsSettings.touchToToggleAimp ? _triggerAimpPlay : null,
                      onDoubleTap: (widget.ttsSettings.doubleTapToCompleteKm && _buttonsEnabled) ? _goToNextKm : null,
                      onLongPress: _buttonsEnabled ? _pauseSession : null,
                      behavior: HitTestBehavior.opaque,
                      child: RunStatsView(session: _session),
                    ),
                  ),

                  // Buttons are outside the GestureDetector so they work normally
                  RunControls(
                    enabled: _buttonsEnabled,
                    canGoPrevious: _session.currentKm > 1,
                    isLastKilometer: _session.isLastKilometer,
                    onPrevious: _goToPreviousKm,
                    onNext: _goToNextKm,
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          if (_showFlash)
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.white,
            ),

          if (_isPaused) PausedOverlay(onContinue: _continueSession),
        ],
      ),
    );
  }
}