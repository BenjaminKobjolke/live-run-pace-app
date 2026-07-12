import '../models/running_session.dart';

/// Builds the spoken progress announcement for a [RunningSession].
///
/// Pure string logic extracted from the main screen so it can be unit-tested
/// without a widget or TTS engine.
class AnnouncementBuilder {
  AnnouncementBuilder._();

  /// Returns the announcement text for the just-completed kilometer and the
  /// next target of [session].
  static String build(RunningSession session) {
    final justCompletedKm = session.currentKm - 1;
    final nextTargetKm = session.currentKm;

    if (session.isLastKilometer) {
      final timeLeft = session.timeLeftForCurrentKm;
      final absTime = timeLeft.abs();
      final minutes = absTime.inMinutes;
      final seconds = absTime.inSeconds % 60;

      if (session.isPartialLastKilometer) {
        final meters = (session.lastSegmentDistance * 1000).round();
        return "Final $meters meters! You have $minutes minutes and $seconds seconds left to finish.";
      }
      return "Final kilometer! You have $minutes minutes and $seconds seconds left to finish.";
    }

    final paceStatus = session.paceStatus;
    final timeLeft = session.timeLeftForCurrentKm;
    final absTime = timeLeft.abs();
    final minutes = absTime.inMinutes;
    final seconds = absTime.inSeconds % 60;

    // Check if the NEXT kilometer will be a partial one
    final isNextPartial = (nextTargetKm == session.totalKilometers) &&
        (session.distance - (nextTargetKm - 1)) < 1.0;
    String nextTargetDescription;

    if (isNextPartial) {
      final nextSegmentDistance = session.distance - (nextTargetKm - 1);
      final meters = (nextSegmentDistance * 1000).round();
      nextTargetDescription = "the final $meters meters";
    } else {
      nextTargetDescription = "kilometer $nextTargetKm";
    }

    switch (paceStatus) {
      case PaceStatus.onSchedule:
        return "Kilometer $justCompletedKm completed in time! The next target is $nextTargetDescription. You have $minutes minutes and $seconds seconds left to reach the next target.";
      case PaceStatus.behindSchedule:
        final maxPaceMinutes = session.maxPace.inMinutes;
        final maxPaceSeconds = session.maxPace.inSeconds % 60;
        if (isNextPartial) {
          // For partial segments, adjust the catch-up time proportionally
          final nextSegmentDistance = session.distance - (nextTargetKm - 1);
          final adjustedMaxPaceSeconds = (session.maxPace.inSeconds * nextSegmentDistance).round();
          final adjMinutes = adjustedMaxPaceSeconds ~/ 60;
          final adjSeconds = adjustedMaxPaceSeconds % 60;
          return "Kilometer $justCompletedKm completed. You're behind schedule. Run $nextTargetDescription in $adjMinutes minutes and $adjSeconds seconds to catch up.";
        }
        return "Kilometer $justCompletedKm completed. You're behind schedule. Run the next kilometer in $maxPaceMinutes minutes and $maxPaceSeconds seconds to catch up.";
      case PaceStatus.aheadOfSchedule:
        return "Kilometer $justCompletedKm completed. Slow down! You have $minutes minutes and $seconds seconds left to reach $nextTargetDescription!";
    }
  }
}
