class TtsSettings {
  final bool enabled;
  final double speed;
  final double volume;
  final bool pauseOtherAudio;
  final List<String> mp3FilePaths;
  final bool resumeAimpAfterPlayback;
  final bool touchToToggleAimp;
  final bool doubleTapToCompleteKm;

  const TtsSettings({
    this.enabled = true,
    this.speed = 0.4,
    this.volume = 1.5,
    this.pauseOtherAudio = true,
    this.mp3FilePaths = const [],
    this.resumeAimpAfterPlayback = false,
    this.touchToToggleAimp = false,
    this.doubleTapToCompleteKm = false,
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
  };

  factory TtsSettings.fromJson(Map<String, dynamic> json) {
    // Handle backward compatibility: convert old single mp3FilePath to list
    List<String> mp3Paths = [];
    if (json['mp3FilePaths'] != null) {
      // New format: list of paths
      mp3Paths = List<String>.from(json['mp3FilePaths'] as List? ?? []);
    } else if (json['mp3FilePath'] != null) {
      // Old format: single path, convert to list
      mp3Paths = [json['mp3FilePath'] as String];
    }

    return TtsSettings(
      enabled: json['enabled'] as bool? ?? true,
      speed: (json['speed'] as num?)?.toDouble() ?? 0.4,
      volume: (json['volume'] as num?)?.toDouble() ?? 1.5,
      pauseOtherAudio: json['pauseOtherAudio'] as bool? ?? true,
      mp3FilePaths: mp3Paths,
      resumeAimpAfterPlayback: json['resumeAimpAfterPlayback'] as bool? ?? false,
      touchToToggleAimp: json['touchToToggleAimp'] as bool? ?? false,
      doubleTapToCompleteKm: json['doubleTapToCompleteKm'] as bool? ?? false,
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
  }) => TtsSettings(
    enabled: enabled ?? this.enabled,
    speed: speed ?? this.speed,
    volume: volume ?? this.volume,
    pauseOtherAudio: pauseOtherAudio ?? this.pauseOtherAudio,
    mp3FilePaths: mp3FilePaths ?? this.mp3FilePaths,
    resumeAimpAfterPlayback: resumeAimpAfterPlayback ?? this.resumeAimpAfterPlayback,
    touchToToggleAimp: touchToToggleAimp ?? this.touchToToggleAimp,
    doubleTapToCompleteKm: doubleTapToCompleteKm ?? this.doubleTapToCompleteKm,
  );
}