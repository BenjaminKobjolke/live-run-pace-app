import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import '../models/app_settings.dart';
import '../models/gesture_action.dart';
import '../models/run_screen_layout.dart';
import '../models/running_session.dart';
import '../models/tts_settings.dart';
import '../widgets/paused_overlay.dart';
import '../widgets/run_screen_callbacks.dart';
import '../widgets/run_screen_pager.dart';
import '../widgets/confirm_dialog.dart';
import 'run_session_controller.dart';
import 'completion_screen.dart';
import 'home_screen.dart';

/// Live run screen. A thin presenter: session state and its side-effects live in
/// [RunSessionController]; this widget owns only presentation concerns (screen
/// flash, vibration, button debounce), gestures, and navigation. The visible
/// content is the user-configured [RunScreenPager].
class MainScreen extends StatefulWidget {
  final AppSettings settings;
  final TtsSettings ttsSettings;
  final RunScreenLayouts layouts;
  final RunningSession? existingSession;

  const MainScreen({
    super.key,
    required this.settings,
    required this.ttsSettings,
    required this.layouts,
    this.existingSession,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  late final RunSessionController _controller;
  Timer? _buttonDelayTimer;
  bool _showFlash = false;
  bool _buttonsEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = RunSessionController(
      settings: widget.settings,
      ttsSettings: widget.ttsSettings,
      existingSession: widget.existingSession,
    );
    _controller.initTts();

    // New sessions briefly lock the nav buttons; recovered ones are ready now.
    if (widget.existingSession == null) {
      _disableButtonsTemporarily();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _controller.handleLifecycle(state);
  }

  /// Flashes the screen white and vibrates as tactile confirmation of a
  /// kilometer completion. Pure UI feedback — no session state.
  Future<void> _triggerFeedback() async {
    setState(() => _showFlash = true);
    try {
      if (await Vibration.hasVibrator()) {
        await Vibration.vibrate(duration: 200);
      }
    } catch (e) {
      // Vibration not available
    }
    Timer(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _showFlash = false);
    });
  }

  /// Debounces the navigation buttons for one second after an action so a stray
  /// double-press cannot skip a kilometer.
  void _disableButtonsTemporarily() {
    if (!widget.ttsSettings.buttonNavigationDelay) return;

    setState(() => _buttonsEnabled = false);
    _buttonDelayTimer?.cancel();
    _buttonDelayTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) setState(() => _buttonsEnabled = true);
    });
  }

  Future<void> _onNext() async {
    if (_controller.session.isLastKilometer) {
      final ok = await showConfirmDialog(
        context,
        title: 'Finish Session?',
        message: 'Are you sure you want to finish this running session?',
        confirmLabel: 'Finish',
      );
      if (ok) _finish();
      return;
    }
    _triggerFeedback();
    await _controller.goToNextKm();
    _disableButtonsTemporarily();
  }

  void _onPrevious() {
    if (_controller.session.currentKm <= 1) return;
    _controller.goToPreviousKm();
    _disableButtonsTemporarily();
  }

  void _finish() {
    final completed = _controller.finishSession();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => CompletionScreen(session: completed),
      ),
    );
  }

  /// Resolves a configured [GestureAction] to its handler, preserving the
  /// gating each action had when hardwired (navigation actions respect the
  /// button debounce; AIMP toggle and abort are ungated). Returns null when the
  /// action is [GestureAction.none] or currently unavailable, disabling that
  /// gesture on the [GestureDetector].
  VoidCallback? _gestureCallback(GestureAction action) {
    switch (action) {
      case GestureAction.none:
        return null;
      case GestureAction.toggleAimp:
        return _controller.triggerAimpPlay;
      case GestureAction.completeKm:
        return _buttonsEnabled ? _onNext : null;
      case GestureAction.previousKm:
        return _buttonsEnabled ? _onPrevious : null;
      case GestureAction.pause:
        return _buttonsEnabled ? _controller.pauseSession : null;
      case GestureAction.abort:
        return _showAbortConfirmation;
    }
  }

  Future<void> _showAbortConfirmation() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Abort Session?',
      message:
          'Are you sure you want to abort this running session? All progress will be lost.',
      confirmLabel: 'Abort',
      confirmColor: Colors.red,
    );
    if (ok) _abort();
  }

  Future<void> _abort() async {
    await _controller.abortSession();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _buttonDelayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final session = _controller.session;
          final callbacks = RunScreenCallbacks(
            onNext: _onNext,
            onPrevious: _onPrevious,
            onAbort: _showAbortConfirmation,
            buttonsEnabled: _buttonsEnabled,
            canGoPrevious: session.currentKm > 1,
            isLastKilometer: session.isLastKilometer,
          );
          return Stack(
            children: [
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  // The whole page area is a gesture surface (AIMP control,
                  // km completion, pause, ...). The pager's horizontal drags
                  // and the tiles' buttons win their gesture arenas, so all
                  // three input styles coexist.
                  child: GestureDetector(
                    onTap: _gestureCallback(
                      widget.ttsSettings.singleTapAction,
                    ),
                    onDoubleTap: _gestureCallback(
                      widget.ttsSettings.doubleTapAction,
                    ),
                    onLongPress: _gestureCallback(
                      widget.ttsSettings.longPressAction,
                    ),
                    behavior: HitTestBehavior.opaque,
                    child: RunScreenPager(
                      layouts: widget.layouts,
                      session: session,
                      callbacks: callbacks,
                      tick: _controller.tick,
                    ),
                  ),
                ),
              ),

              if (_showFlash)
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.white,
                ),

              if (session.isPaused)
                PausedOverlay(onContinue: _controller.continueSession),
            ],
          );
        },
      ),
    );
  }
}
