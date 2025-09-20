class TtsSettings {
  final bool enabled;
  final double speed;
  final double volume;
  final bool pauseOtherAudio;
  final String? mp3FilePath;

  const TtsSettings({
    this.enabled = true,
    this.speed = 0.4,
    this.volume = 1.5,
    this.pauseOtherAudio = true,
    this.mp3FilePath,
  });

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'speed': speed,
    'volume': volume,
    'pauseOtherAudio': pauseOtherAudio,
    'mp3FilePath': mp3FilePath,
  };

  factory TtsSettings.fromJson(Map<String, dynamic> json) => TtsSettings(
    enabled: json['enabled'] as bool? ?? true,
    speed: (json['speed'] as num?)?.toDouble() ?? 0.4,
    volume: (json['volume'] as num?)?.toDouble() ?? 1.5,
    pauseOtherAudio: json['pauseOtherAudio'] as bool? ?? true,
    mp3FilePath: json['mp3FilePath'] as String?,
  );

  TtsSettings copyWith({
    bool? enabled,
    double? speed,
    double? volume,
    bool? pauseOtherAudio,
    String? mp3FilePath,
  }) => TtsSettings(
    enabled: enabled ?? this.enabled,
    speed: speed ?? this.speed,
    volume: volume ?? this.volume,
    pauseOtherAudio: pauseOtherAudio ?? this.pauseOtherAudio,
    mp3FilePath: mp3FilePath ?? this.mp3FilePath,
  );
}