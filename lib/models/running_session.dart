// Display-only formatting getters live in an extension re-exported here, so
// importing this file makes them available without a second import.
export 'running_session_display.dart';

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

  bool get isOverTime => timeLeftForCurrentKm.isNegative;

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

  int get completedKilometers {
    return targets.where((t) => t.actualTime != null).length;
  }

  double get distanceCompleted {
    return completedKilometers.toDouble();
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