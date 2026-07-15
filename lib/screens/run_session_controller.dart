import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import '../models/app_settings.dart';
import '../models/running_session.dart';
import '../models/tts_settings.dart';
import '../services/storage_service.dart';
import '../services/tts_speaker.dart';
import '../services/app_logger.dart';
import '../services/announcement_builder.dart';

/// Owns the live running-session state machine and its side-effects (timers,
/// persistence, TTS announcements, AIMP control) so the screen widget stays a
/// thin presenter. Extends [ChangeNotifier] — Flutter's stdlib observable — so
/// the widget rebuilds via `ListenableBuilder` without a bloc/Cubit dependency.
///
/// Navigation and pure UI feedback (screen flash, vibration, button debounce)
/// intentionally stay in the widget; this controller never touches
/// `BuildContext` or `Navigator`.
class RunSessionController extends ChangeNotifier {
  /// Static run configuration for a brand-new session.
  final AppSettings settings;

  /// Audio/gesture configuration for TTS and AIMP behaviour.
  final TtsSettings ttsSettings;

  static const MethodChannel _aimpChannel = MethodChannel(
    'com.yourapp.live_run_pace/aimp',
  );

  late RunningSession _session;
  Timer? _timer;
  Timer? _saveTimer;
  TtsSpeaker? _ttsSpeaker;
  bool _isAppInBackground = false;
  bool _isNewSession = false;

  /// Creates the controller and immediately initialises the session (recovering
  /// [existingSession] or starting a fresh run from [settings]) and its timers.
  /// Call [initTts] afterwards to bring up the TTS engine.
  RunSessionController({
    required this.settings,
    required this.ttsSettings,
    RunningSession? existingSession,
  }) {
    _initializeSession(existingSession);
    _startTimers();
  }

  /// The current session snapshot; the widget reads all derived display values
  /// (elapsed time, pace status, paused state) from here.
  RunningSession get session => _session;

  /// Brings up the TTS engine; safe to call fire-and-forget. On failure TTS is
  /// disabled for the session and announcements become no-ops.
  Future<void> initTts() async {
    _ttsSpeaker = TtsSpeaker(ttsSettings);
    try {
      await _ttsSpeaker!.init();
      // Only a fresh run announces its start; recovery would re-announce.
      if (_isNewSession) _ttsSpeaker?.speak('Session started.');
    } catch (e) {
      AppLogger.e('TTS Speaker initialization failed', error: e);
      _ttsSpeaker = null;
    }
  }

  void _initializeSession(RunningSession? existingSession) {
    if (existingSession != null) {
      _session = existingSession; // may be recovered mid-pause
      return;
    }

    _isNewSession = true;

    final targets = List.generate(
      settings.distance.ceil(),
      (index) => KilometerTarget(kmNumber: index + 1),
    );
    _session = RunningSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      distance: settings.distance,
      targetPace: settings.targetPace,
      maxPace: settings.maxPace,
      startTime: DateTime.now(),
      targets: targets,
    );
    _saveSession();
    _recordDistanceToHistory();
  }

  void _startTimers() {
    if (_session.isPaused) return; // frozen while paused
    if (_isAppInBackground) return;

    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!_isAppInBackground) notifyListeners();
    });
    _saveTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!_isAppInBackground) _saveSession();
    });
  }

  void _stopTimers() {
    _timer?.cancel();
    _timer = null;
    _saveTimer?.cancel();
    _saveTimer = null;
  }

  Future<void> _saveSession() async {
    await StorageService.instance.saveActiveSession(_session);
  }

  Future<void> _recordDistanceToHistory() async {
    try {
      await StorageService.instance.addDistanceToHistory(_session.distance);
    } catch (e) {
      AppLogger.e('Error recording distance to history', error: e);
    }
  }

  /// Pauses the run: freezes the clock at now and stops timers.
  void pauseSession() {
    _stopTimers();
    _session = _session.copyWith(pausedAt: DateTime.now());
    notifyListeners();
    _saveSession();
    _ttsSpeaker?.speak('Session paused.'); // no-op if TTS disabled
  }

  /// Resumes a paused run, shifting [RunningSession.startTime] forward by the
  /// paused gap so elapsed time continues exactly where it left off.
  void continueSession() {
    final pausedGap = DateTime.now().difference(_session.pausedAt!);
    _session = _session.copyWith(
      startTime: _session.startTime.add(pausedGap),
      clearPausedAt: true,
    );
    notifyListeners();
    _startTimers();
    _saveSession();
    _ttsSpeaker?.speak('Session resumed.'); // no-op if TTS disabled
  }

  /// Marks the current kilometer complete and advances. Caller must ensure this
  /// is not the last kilometer (use [RunningSession.isLastKilometer] and
  /// [finishSession] for the final one).
  Future<void> goToNextKm() async {
    final updatedTargets = List<KilometerTarget>.from(_session.targets);
    updatedTargets[_session.currentKm -
        1] = updatedTargets[_session.currentKm - 1].copyWith(
      completedAt: DateTime.now(),
      actualTime: _session.elapsedTime,
    );
    _session = _session.copyWith(
      targets: updatedTargets,
      currentKm: _session.currentKm + 1,
    );
    notifyListeners();
    await _announceProgress();
    _saveSession();
  }

  /// Steps back one kilometer, clearing that target's completion, when not on
  /// the first kilometer.
  void goToPreviousKm() {
    if (_session.currentKm <= 1) return;

    final updatedTargets = List<KilometerTarget>.from(_session.targets);
    updatedTargets[_session.currentKm -
        1] = updatedTargets[_session.currentKm - 1].copyWith(
      completedAt: null,
      actualTime: null,
    );
    _session = _session.copyWith(
      targets: updatedTargets,
      currentKm: _session.currentKm - 1,
    );
    notifyListeners();
    _saveSession();
  }

  Future<void> _announceProgress() async {
    if (_isAppInBackground || _ttsSpeaker == null) return;
    try {
      await _ttsSpeaker!.speak(
        AnnouncementBuilder.build(_session),
        playMp3: true,
      );
    } catch (e) {
      AppLogger.e('Announcement error', error: e);
    }
  }

  /// Completes the run: records the final kilometer, persists to history, clears
  /// the active session, and returns the completed session for the caller to
  /// navigate to a summary screen.
  RunningSession finishSession() {
    final updatedTargets = List<KilometerTarget>.from(_session.targets);
    updatedTargets[_session.currentKm -
        1] = updatedTargets[_session.currentKm - 1].copyWith(
      completedAt: DateTime.now(),
      actualTime: _session.elapsedTime,
    );
    final completed = _session.copyWith(
      targets: updatedTargets,
      isCompleted: true,
    );
    StorageService.instance.saveSessionToHistory(completed);
    StorageService.instance.clearActiveSession();
    // Detach the speaker: the caller navigates away immediately, disposing this
    // controller — the speech must outlive it, then clean itself up.
    final speaker = _ttsSpeaker;
    _ttsSpeaker = null;
    speaker?.speak('Session complete.').whenComplete(speaker.dispose);
    return completed;
  }

  /// Aborts the run: persists an aborted record to history and clears the active
  /// session. The caller navigates away afterwards.
  Future<void> abortSession() async {
    final aborted = _session.copyWith(isAborted: true);
    await StorageService.instance.saveSessionToHistory(aborted);
    await StorageService.instance.clearActiveSession();
  }

  /// Toggles the AIMP music player (play/pause) via the native channel.
  Future<void> triggerAimpPlay() async {
    try {
      AppLogger.d('Triggering AIMP toggle from screen tap');
      await _aimpChannel.invokeMethod('toggleAimp');
      AppLogger.d('AIMP toggle command sent');
    } catch (e) {
      AppLogger.e('Error triggering AIMP toggle', error: e);
    }
  }

  /// Reacts to app lifecycle changes: stops timers and persists when the app
  /// leaves the foreground, restarts them on resume.
  void handleLifecycle(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
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
    }
  }

  @override
  void dispose() {
    _stopTimers();
    final speaker = _ttsSpeaker;
    _ttsSpeaker = null;
    if (speaker != null) {
      // Fire-and-forget async cleanup; controller is already tearing down.
      speaker.dispose().catchError(
        (e) => AppLogger.e('TTS Speaker cleanup failed', error: e),
      );
    }
    super.dispose();
  }
}
