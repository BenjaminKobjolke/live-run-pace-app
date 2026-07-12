class TtsSettings {
  final bool enabled;
  final double speed;
  final double volume;
  final bool pauseOtherAudio;
  final List<String> mp3FilePaths;
  final bool resumeAimpAfterPlayback;
  final bool touchToToggleAimp;
  final bool doubleTapToCompleteKm;
  final bool buttonNavigationDelay;
  final int delayAfterAudioMs;

  const TtsSettings({
    this.enabled = true,
    this.speed = 0.4,
    this.volume = 1.5,
    this.pauseOtherAudio = true,
    this.mp3FilePaths = const [],
    this.resumeAimpAfterPlayback = false,
    this.touchToToggleAimp = false,
    this.doubleTapToCompleteKm = false,
    this.buttonNavigationDelay = true,
    this.delayAfterAudioMs = 1000,
  });

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'speed': speed,
    'volume': volume,
    'pauseOtherAudio': pauseOtherAudio,
    'mp3FilePaths': mp3FilePaths,
    'resumeAimpAfterPlayback': resumeAimpAfterPlayback,
    'touchToToggleAimp': touchToToggleAimp,
    'doubleTapToCompleteKm': doubleTapToCompleteKm,
    'buttonNavigationDelay': buttonNavigationDelay,
    'delayAfterAudioMs': delayAfterAudioMs,
  };

  factory TtsSettings.fromJson(Map<String, dynamic> json) {
    return TtsSettings(
      enabled: json['enabled'] as bool? ?? true,
      speed: (json['speed'] as num?)?.toDouble() ?? 0.4,
      volume: (json['volume'] as num?)?.toDouble() ?? 1.5,
      pauseOtherAudio: json['pauseOtherAudio'] as bool? ?? true,
      mp3FilePaths: _readMp3FilePaths(json),
      resumeAimpAfterPlayback:
          json['resumeAimpAfterPlayback'] as bool? ?? false,
      touchToToggleAimp: json['touchToToggleAimp'] as bool? ?? false,
      doubleTapToCompleteKm: json['doubleTapToCompleteKm'] as bool? ?? false,
      buttonNavigationDelay: json['buttonNavigationDelay'] as bool? ?? true,
      delayAfterAudioMs: (json['delayAfterAudioMs'] as num?)?.toInt() ?? 1000,
    );
  }

  TtsSettings copyWith({
    bool? enabled,
    double? speed,
    double? volume,
    bool? pauseOtherAudio,
    List<String>? mp3FilePaths,
    bool? resumeAimpAfterPlayback,
    bool? touchToToggleAimp,
    bool? doubleTapToCompleteKm,
    bool? buttonNavigationDelay,
    int? delayAfterAudioMs,
  }) => TtsSettings(
    enabled: enabled ?? this.enabled,
    speed: speed ?? this.speed,
    volume: volume ?? this.volume,
    pauseOtherAudio: pauseOtherAudio ?? this.pauseOtherAudio,
    mp3FilePaths: mp3FilePaths ?? this.mp3FilePaths,
    resumeAimpAfterPlayback:
        resumeAimpAfterPlayback ?? this.resumeAimpAfterPlayback,
    touchToToggleAimp: touchToToggleAimp ?? this.touchToToggleAimp,
    doubleTapToCompleteKm: doubleTapToCompleteKm ?? this.doubleTapToCompleteKm,
    buttonNavigationDelay: buttonNavigationDelay ?? this.buttonNavigationDelay,
    delayAfterAudioMs: delayAfterAudioMs ?? this.delayAfterAudioMs,
  );
}

List<String> _readMp3FilePaths(Map<String, dynamic> json) {
  final paths = json['mp3FilePaths'];
  if (paths is List) {
    return List<String>.from(paths);
  }

  final legacyPath = json['mp3FilePath'];
  if (legacyPath is String) {
    return [legacyPath];
  }

  return [];
}
