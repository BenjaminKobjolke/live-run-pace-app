class AppSettings {
  final double distance;
  final int paceMinutes;
  final int paceSeconds;

  const AppSettings({
    this.distance = 42.195,
    this.paceMinutes = 6,
    this.paceSeconds = 0,
  });

  Duration get targetPace => Duration(minutes: paceMinutes, seconds: paceSeconds);

  Duration get totalEstimatedTime {
    final pacePerKm = targetPace;
    final totalSeconds = (distance * pacePerKm.inSeconds).round();
    return Duration(seconds: totalSeconds);
  }

  String get paceDisplay => '$paceMinutes:${paceSeconds.toString().padLeft(2, '0')}';

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
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    distance: (json['distance'] as num?)?.toDouble() ?? 42.195,
    paceMinutes: json['paceMinutes'] as int? ?? 6,
    paceSeconds: json['paceSeconds'] as int? ?? 0,
  );

  AppSettings copyWith({
    double? distance,
    int? paceMinutes,
    int? paceSeconds,
  }) => AppSettings(
    distance: distance ?? this.distance,
    paceMinutes: paceMinutes ?? this.paceMinutes,
    paceSeconds: paceSeconds ?? this.paceSeconds,
  );
}