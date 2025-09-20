class AppSettings {
  final double distance;
  final int paceMinutes;
  final int paceSeconds;
  final int maxPaceMinutes;
  final int maxPaceSeconds;

  const AppSettings({
    this.distance = 42.195,
    this.paceMinutes = 6,
    this.paceSeconds = 0,
    this.maxPaceMinutes = 5,
    this.maxPaceSeconds = 45,
  });

  Duration get targetPace => Duration(minutes: paceMinutes, seconds: paceSeconds);
  Duration get maxPace => Duration(minutes: maxPaceMinutes, seconds: maxPaceSeconds);

  Duration get totalEstimatedTime {
    final pacePerKm = targetPace;
    final totalSeconds = (distance * pacePerKm.inSeconds).round();
    return Duration(seconds: totalSeconds);
  }

  String get paceDisplay => '$paceMinutes:${paceSeconds.toString().padLeft(2, '0')}';
  String get maxPaceDisplay => '$maxPaceMinutes:${maxPaceSeconds.toString().padLeft(2, '0')}';

  String get finishTimeDisplay {
    final total = totalEstimatedTime;
    final hours = total.inHours;
    final minutes = total.inMinutes % 60;
    final seconds = total.inSeconds % 60;
    return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() => {
    'distance': distance,
    'paceMinutes': paceMinutes,
    'paceSeconds': paceSeconds,
    'maxPaceMinutes': maxPaceMinutes,
    'maxPaceSeconds': maxPaceSeconds,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    distance: (json['distance'] as num?)?.toDouble() ?? 42.195,
    paceMinutes: json['paceMinutes'] as int? ?? 6,
    paceSeconds: json['paceSeconds'] as int? ?? 0,
    maxPaceMinutes: json['maxPaceMinutes'] as int? ?? 5,
    maxPaceSeconds: json['maxPaceSeconds'] as int? ?? 45,
  );

  AppSettings copyWith({
    double? distance,
    int? paceMinutes,
    int? paceSeconds,
    int? maxPaceMinutes,
    int? maxPaceSeconds,
  }) => AppSettings(
    distance: distance ?? this.distance,
    paceMinutes: paceMinutes ?? this.paceMinutes,
    paceSeconds: paceSeconds ?? this.paceSeconds,
    maxPaceMinutes: maxPaceMinutes ?? this.maxPaceMinutes,
    maxPaceSeconds: maxPaceSeconds ?? this.maxPaceSeconds,
  );
}