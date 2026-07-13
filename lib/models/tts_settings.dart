import 'gesture_action.dart';

class TtsSettings {
  final bool enabled;
  final double speed;
  final double volume;
  final bool pauseOtherAudio;
  final List<String> mp3FilePaths;

  /// Last-picked MP3 folder, or null if none. Enables the "Refresh" re-scan.
  final String? mp3FolderPath;
  final bool resumeAimpAfterPlayback;

  /// Action for a single tap on the main run screen.
  final GestureAction singleTapAction;

  /// Action for a double tap on the main run screen.
  final GestureAction doubleTapAction;

  /// Action for a long press on the main run screen.
  final GestureAction longPressAction;
  final bool buttonNavigationDelay;
  final int delayAfterAudioMs;

  const TtsSettings({
    this.enabled = true,
    this.speed = 0.4,
    this.volume = 1.5,
    this.pauseOtherAudio = true,
    this.mp3FilePaths = const [],
    this.mp3FolderPath,
    this.resumeAimpAfterPlayback = false,
    this.singleTapAction = GestureAction.none,
    this.doubleTapAction = GestureAction.none,
    this.longPressAction = GestureAction.pause,
    this.buttonNavigationDelay = true,
    this.delayAfterAudioMs = 1000,
  });

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'speed': speed,
    'volume': volume,
    'pauseOtherAudio': pauseOtherAudio,
    'mp3FilePaths': mp3FilePaths,
    'mp3FolderPath': mp3FolderPath,
    'resumeAimpAfterPlayback': resumeAimpAfterPlayback,
    'singleTapAction': singleTapAction.name,
    'doubleTapAction': doubleTapAction.name,
    'longPressAction': longPressAction.name,
    'buttonNavigationDelay': buttonNavigationDelay,
    'delayAfterAudioMs': delayAfterAudioMs,
  };

  factory TtsSettings.fromJson(Map<String, dynamic> json) => TtsSettings(
    enabled: json['enabled'] as bool? ?? true,
    speed: (json['speed'] as num?)?.toDouble() ?? 0.4,
    volume: (json['volume'] as num?)?.toDouble() ?? 1.5,
    pauseOtherAudio: json['pauseOtherAudio'] as bool? ?? true,
    mp3FilePaths: _mp3FilePaths(json),
    mp3FolderPath: json['mp3FolderPath'] as String?,
    resumeAimpAfterPlayback: json['resumeAimpAfterPlayback'] as bool? ?? false,
    singleTapAction: _singleTapAction(json),
    doubleTapAction: _doubleTapAction(json),
    longPressAction: _gestureAction(
      json['longPressAction'],
      GestureAction.pause,
    ),
    buttonNavigationDelay: json['buttonNavigationDelay'] as bool? ?? true,
    delayAfterAudioMs: (json['delayAfterAudioMs'] as num?)?.toInt() ?? 1000,
  );

  static List<String> _mp3FilePaths(Map<String, dynamic> json) {
    final paths = json['mp3FilePaths'];
    if (paths is List) return List<String>.from(paths);

    final legacyPath = json['mp3FilePath'];
    if (legacyPath is String) return [legacyPath];

    return [];
  }

  static GestureAction _singleTapAction(Map<String, dynamic> json) =>
      _gestureAction(
        json['singleTapAction'],
        _legacyGesture(json['touchToToggleAimp'], GestureAction.toggleAimp),
      );

  static GestureAction _doubleTapAction(Map<String, dynamic> json) =>
      _gestureAction(
        json['doubleTapAction'],
        _legacyGesture(json['doubleTapToCompleteKm'], GestureAction.completeKm),
      );

  static GestureAction _legacyGesture(dynamic value, GestureAction action) =>
      value == true ? action : GestureAction.none;

  /// Parses a stored gesture-action name, falling back to [fallback] when the
  /// value is absent or unrecognised.
  static GestureAction _gestureAction(dynamic value, GestureAction fallback) {
    if (value is String) {
      return GestureAction.values.asNameMap()[value] ?? fallback;
    }
    return fallback;
  }

  TtsSettings copyWith({
    bool? enabled,
    double? speed,
    double? volume,
    bool? pauseOtherAudio,
    List<String>? mp3FilePaths,
    String? mp3FolderPath,
    bool? resumeAimpAfterPlayback,
    GestureAction? singleTapAction,
    GestureAction? doubleTapAction,
    GestureAction? longPressAction,
    bool? buttonNavigationDelay,
    int? delayAfterAudioMs,
  }) => TtsSettings(
    enabled: enabled ?? this.enabled,
    speed: speed ?? this.speed,
    volume: volume ?? this.volume,
    pauseOtherAudio: pauseOtherAudio ?? this.pauseOtherAudio,
    mp3FilePaths: mp3FilePaths ?? this.mp3FilePaths,
    mp3FolderPath: mp3FolderPath ?? this.mp3FolderPath,
    resumeAimpAfterPlayback:
        resumeAimpAfterPlayback ?? this.resumeAimpAfterPlayback,
    singleTapAction: singleTapAction ?? this.singleTapAction,
    doubleTapAction: doubleTapAction ?? this.doubleTapAction,
    longPressAction: longPressAction ?? this.longPressAction,
    buttonNavigationDelay: buttonNavigationDelay ?? this.buttonNavigationDelay,
    delayAfterAudioMs: delayAfterAudioMs ?? this.delayAfterAudioMs,
  );
}
