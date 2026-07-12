import 'running_session.dart';

/// Formats a [Duration] as `h:mm:ss` (hours omitted when zero).
String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;
  final seconds = duration.inSeconds % 60;

  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

/// Human-readable, display-only formatting for a [RunningSession]. Kept separate
/// from the domain/model logic in `running_session.dart` (re-exported from it,
/// so importers get these getters automatically).
extension RunningSessionDisplay on RunningSession {
  String get nextTargetTimeDisplay => _formatDuration(nextTargetTime);

  String get currentTimeDisplay => _formatDuration(elapsedTime);

  String get timeLeftDisplay {
    final left = timeLeftForCurrentKm;
    final timeString = _formatDuration(left.abs());
    return left.isNegative ? '-$timeString' : timeString;
  }

  String get finishTimeDisplay {
    final completedKm = currentKm - 1;

    // If no km completed yet, show original estimated finish time
    if (completedKm == 0) {
      return originalEstimatedFinishTime;
    }

    final elapsed = elapsedTime;
    final remainingKm = distance - completedKm;

    // Calculate estimated remaining time based on target pace
    final estimatedRemainingTime = Duration(
      seconds: (remainingKm * targetPace.inSeconds).round(),
    );

    return _formatDuration(elapsed + estimatedRemainingTime);
  }

  String get originalEstimatedFinishTime {
    final total = Duration(seconds: (distance * targetPace.inSeconds).round());
    return _formatDuration(total);
  }

  String get currentSegmentDistanceDisplay {
    if (isPartialLastKilometer) {
      final meters = (lastSegmentDistance * 1000).round();
      if (meters < 1000) {
        return '$meters m';
      }
      return '${lastSegmentDistance.toStringAsFixed(3)} km';
    }
    return '$currentKm km';
  }

  String get currentPaceDisplay {
    if (currentKm <= 1) return '--:--';

    final avgTimePerKm = elapsedTime.inSeconds / (currentKm - 1);
    final minutes = (avgTimePerKm / 60).floor();
    final seconds = (avgTimePerKm % 60).round();
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String get averagePaceDisplay {
    final pace = averagePace;
    if (pace == Duration.zero) return '--:--';

    final minutes = pace.inMinutes;
    final seconds = pace.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String get statusDisplay {
    if (isAborted) return 'Aborted';
    if (isCompleted) return 'Completed';
    return 'In Progress';
  }

  String get completionSummary {
    if (isAborted) {
      if (completedKilometers == 0) {
        return 'Aborted before completing any kilometers';
      }
      return 'Aborted after $completedKilometers of ${distance.toStringAsFixed(1)} km';
    }
    if (isCompleted) {
      return 'Completed ${distance.toStringAsFixed(1)} km';
    }
    return 'In progress: $completedKilometers of ${distance.toStringAsFixed(1)} km';
  }
}
