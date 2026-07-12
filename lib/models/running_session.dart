enum PaceStatus {
  onSchedule,
  behindSchedule,
  aheadOfSchedule,
}

class KilometerTarget {
  final int kmNumber;
  final DateTime? completedAt;
  final Duration? actualTime;

  const KilometerTarget({
    required this.kmNumber,
    this.completedAt,
    this.actualTime,
  });

  String get actualPaceDisplay {
    if (actualTime == null) return '--:--';
    final minutes = actualTime!.inMinutes;
    final seconds = actualTime!.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String get timeDisplay {
    if (actualTime == null) return '--:--';
    final minutes = actualTime!.inMinutes;
    final seconds = actualTime!.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() => {
    'kmNumber': kmNumber,
    'completedAt': completedAt?.toIso8601String(),
    'actualTimeSeconds': actualTime?.inSeconds,
  };

  factory KilometerTarget.fromJson(Map<String, dynamic> json) => KilometerTarget(
    kmNumber: json['kmNumber'] as int,
    completedAt: json['completedAt'] != null
        ? DateTime.parse(json['completedAt'] as String)
        : null,
    actualTime: json['actualTimeSeconds'] != null
        ? Duration(seconds: json['actualTimeSeconds'] as int)
        : null,
  );

  KilometerTarget copyWith({
    int? kmNumber,
    DateTime? completedAt,
    Duration? actualTime,
  }) => KilometerTarget(
    kmNumber: kmNumber ?? this.kmNumber,
    completedAt: completedAt ?? this.completedAt,
    actualTime: actualTime ?? this.actualTime,
  );
}

class RunningSession {
  final String id;
  final double distance;
  final Duration targetPace;
  final Duration maxPace;
  final DateTime startTime;
  final List<KilometerTarget> targets;
  final int currentKm;
  final bool isCompleted;
  final bool isAborted;
  final DateTime? pausedAt;

  const RunningSession({
    required this.id,
    required this.distance,
    required this.targetPace,
    required this.maxPace,
    required this.startTime,
    required this.targets,
    this.currentKm = 1,
    this.isCompleted = false,
    this.isAborted = false,
    this.pausedAt,
  });

  int get totalKilometers => distance.ceil();

  bool get isPaused => pausedAt != null;

  // While paused, freeze the clock at pausedAt so all derived values hold still.
  Duration get elapsedTime => (pausedAt ?? DateTime.now()).difference(startTime);

  Duration get targetTimeForCurrentKm {
    if (isPartialLastKilometer) {
      // For partial last kilometer, calculate proportional time
      final previousKmTime = Duration(seconds: (targetPace.inSeconds * (currentKm - 1)).round());
      final partialTime = Duration(seconds: (targetPace.inSeconds * lastSegmentDistance).round());
      return previousKmTime + partialTime;
    }
    return Duration(seconds: (targetPace.inSeconds * currentKm).round());
  }

  Duration get timeLeftForCurrentKm {
    final targetTime = targetTimeForCurrentKm;
    final remaining = targetTime - elapsedTime;
    return remaining;
  }

  Duration get nextTargetTime {
    if (isPartialLastKilometer) {
      // For partial last kilometer, calculate proportional time
      final previousKmTime = Duration(seconds: (targetPace.inSeconds * (currentKm - 1)).round());
      final partialTime = Duration(seconds: (targetPace.inSeconds * lastSegmentDistance).round());
      return previousKmTime + partialTime;
    }
    return Duration(seconds: (targetPace.inSeconds * currentKm).round());
  }

  // Helper method to format duration consistently
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
  }

  String get nextTargetTimeDisplay {
    return _formatDuration(nextTargetTime);
  }

  String get currentTimeDisplay {
    return _formatDuration(elapsedTime);
  }

  String get timeLeftDisplay {
    final left = timeLeftForCurrentKm;
    final absLeft = left.abs();
    final timeString = _formatDuration(absLeft);
    return left.isNegative ? '-$timeString' : timeString;
  }

  bool get isOverTime => timeLeftForCurrentKm.isNegative;

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

    final estimatedTotal = elapsed + estimatedRemainingTime;
    return _formatDuration(estimatedTotal);
  }

  String get originalEstimatedFinishTime {
    final total = Duration(seconds: (distance * targetPace.inSeconds).round());
    return _formatDuration(total);
  }

  bool get isLastKilometer => currentKm >= totalKilometers;

  // Computed properties for partial last kilometer handling
  double get lastSegmentDistance {
    // If we're on the last segment, calculate actual distance
    if (currentKm == totalKilometers) {
      final fractionalPart = distance - (totalKilometers - 1);
      return fractionalPart;
    }
    return 1.0; // Full kilometer for non-last segments
  }

  bool get isPartialLastKilometer {
    return isLastKilometer && lastSegmentDistance < 1.0;
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

  bool get isAheadOfSchedule {
    if (currentKm <= 1) return true;

    final expectedTime = Duration(seconds: (targetPace.inSeconds * (currentKm - 1)).round());
    return elapsedTime < expectedTime;
  }

  PaceStatus get paceStatus {
    if (currentKm <= 1) return PaceStatus.onSchedule;

    final expectedTime = Duration(seconds: (targetPace.inSeconds * (currentKm - 1)).round());
    final elapsedSeconds = elapsedTime.inSeconds;
    final expectedSeconds = expectedTime.inSeconds;

    // Calculate percentage difference
    final difference = (elapsedSeconds - expectedSeconds) / expectedSeconds;

    if (difference > 0.1) {
      return PaceStatus.behindSchedule; // More than 10% slower
    } else if (difference < -0.1) {
      return PaceStatus.aheadOfSchedule; // More than 10% faster
    } else {
      return PaceStatus.onSchedule; // Within ±10%
    }
  }

  // Additional computed properties for session history
  Duration get totalTime {
    if (!isCompleted) return elapsedTime;

    // For completed sessions, calculate from completed targets
    final completedTargets = targets.where((t) => t.completedAt != null).toList();
    if (completedTargets.isEmpty) return Duration.zero;

    final startTime = completedTargets.first.completedAt!.subtract(completedTargets.first.actualTime ?? Duration.zero);
    final endTime = completedTargets.last.completedAt!;
    return endTime.difference(startTime);
  }

  Duration get averagePace {
    final completedTargets = targets.where((t) => t.actualTime != null).toList();
    if (completedTargets.isEmpty) return Duration.zero;

    final totalTime = completedTargets.fold<Duration>(
      Duration.zero,
      (sum, target) => sum + (target.actualTime ?? Duration.zero),
    );

    return Duration(seconds: (totalTime.inSeconds / completedTargets.length).round());
  }

  String get averagePaceDisplay {
    final pace = averagePace;
    if (pace == Duration.zero) return '--:--';

    final minutes = pace.inMinutes;
    final seconds = pace.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  List<Duration> get lapTimes {
    return targets
        .where((t) => t.actualTime != null)
        .map((t) => t.actualTime!)
        .toList();
  }

  Duration? get bestKmTime {
    final times = lapTimes;
    if (times.isEmpty) return null;
    return times.reduce((a, b) => a.inSeconds < b.inSeconds ? a : b);
  }

  Duration? get worstKmTime {
    final times = lapTimes;
    if (times.isEmpty) return null;
    return times.reduce((a, b) => a.inSeconds > b.inSeconds ? a : b);
  }

  // Computed properties for aborted sessions
  String get statusDisplay {
    if (isAborted) return 'Aborted';
    if (isCompleted) return 'Completed';
    return 'In Progress';
  }

  int get completedKilometers {
    return targets.where((t) => t.actualTime != null).length;
  }

  double get distanceCompleted {
    return completedKilometers.toDouble();
  }

  String get completionSummary {
    if (isAborted) {
      if (completedKilometers == 0) {
        return 'Aborted before completing any kilometers';
      } else {
        return 'Aborted after $completedKilometers of ${distance.toStringAsFixed(1)} km';
      }
    }
    if (isCompleted) {
      return 'Completed ${distance.toStringAsFixed(1)} km';
    }
    return 'In progress: $completedKilometers of ${distance.toStringAsFixed(1)} km';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'distance': distance,
    'targetPaceSeconds': targetPace.inSeconds,
    'maxPaceSeconds': maxPace.inSeconds,
    'startTime': startTime.toIso8601String(),
    'targets': targets.map((t) => t.toJson()).toList(),
    'currentKm': currentKm,
    'isCompleted': isCompleted,
    'isAborted': isAborted,
    'pausedAt': pausedAt?.toIso8601String(),
  };

  factory RunningSession.fromJson(Map<String, dynamic> json) => RunningSession(
    id: json['id'] as String,
    distance: (json['distance'] as num).toDouble(),
    targetPace: Duration(seconds: json['targetPaceSeconds'] as int),
    maxPace: Duration(seconds: json['maxPaceSeconds'] as int? ?? 300), // Default 5:00
    startTime: DateTime.parse(json['startTime'] as String),
    targets: (json['targets'] as List)
        .map((t) => KilometerTarget.fromJson(t as Map<String, dynamic>))
        .toList(),
    currentKm: json['currentKm'] as int? ?? 1,
    isCompleted: json['isCompleted'] as bool? ?? false,
    isAborted: json['isAborted'] as bool? ?? false,
    pausedAt: json['pausedAt'] != null
        ? DateTime.parse(json['pausedAt'] as String)
        : null,
  );

  RunningSession copyWith({
    String? id,
    double? distance,
    Duration? targetPace,
    Duration? maxPace,
    DateTime? startTime,
    List<KilometerTarget>? targets,
    int? currentKm,
    bool? isCompleted,
    bool? isAborted,
    DateTime? pausedAt,
    bool clearPausedAt = false, // ?? idiom can't null a field; use this to clear
  }) => RunningSession(
    id: id ?? this.id,
    distance: distance ?? this.distance,
    targetPace: targetPace ?? this.targetPace,
    maxPace: maxPace ?? this.maxPace,
    startTime: startTime ?? this.startTime,
    targets: targets ?? this.targets,
    currentKm: currentKm ?? this.currentKm,
    isCompleted: isCompleted ?? this.isCompleted,
    isAborted: isAborted ?? this.isAborted,
    pausedAt: clearPausedAt ? null : (pausedAt ?? this.pausedAt),
  );
}