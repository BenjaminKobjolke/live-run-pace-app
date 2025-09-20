import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import '../models/app_settings.dart';
import '../models/running_session.dart';
import '../services/storage_service.dart';
import 'start_screen.dart';
import 'completion_screen.dart';

class MainScreen extends StatefulWidget {
  final AppSettings settings;
  final RunningSession? existingSession;

  const MainScreen({
    super.key,
    required this.settings,
    this.existingSession,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late RunningSession _session;
  Timer? _timer;
  Timer? _saveTimer;
  bool _showFlash = false;

  @override
  void initState() {
    super.initState();
    _initializeSession();
    _startTimers();
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
        startTime: DateTime.now(),
        targets: targets,
      );

      _saveSession();
    }
  }

  void _startTimers() {
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) setState(() {});
    });

    _saveTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _saveSession();
    });
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
    _timer?.cancel();
    _saveTimer?.cancel();
    super.dispose();
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