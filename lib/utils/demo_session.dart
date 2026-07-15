import '../models/running_session.dart';

/// Builds a session with a frozen clock (pausedAt) so all time-derived
/// getters are deterministic and stable: elapsedTime == [elapsed].
///
/// Used by the WYSIWYG screen editor and the widget-editor live preview as
/// demo data, and by tests as their session fixture. With the defaults
/// (km 3, target pace 5:00, 600 s elapsed) the session is on schedule;
/// 1000 s elapsed is over time.
RunningSession demoSession({
  Duration elapsed = const Duration(seconds: 600),
  double distance = 5.0,
  int currentKm = 3,
}) {
  final start = DateTime(2024, 1, 1, 8, 0, 0);
  return RunningSession(
    id: 'demo',
    distance: distance,
    targetPace: const Duration(minutes: 5),
    maxPace: const Duration(minutes: 4, seconds: 30),
    startTime: start,
    pausedAt: start.add(elapsed),
    currentKm: currentKm,
    targets: List.generate(
      distance.ceil(),
      (i) => KilometerTarget(kmNumber: i + 1),
    ),
  );
}
