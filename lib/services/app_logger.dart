import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

/// Central logger — the single place `debugPrint` is called.
///
/// Feature code must call [AppLogger] instead of `print`/`debugPrint` directly,
/// so logging can be silenced or redirected from one flag ([AppConfig.logEnabled]).
class AppLogger {
  AppLogger._();

  /// Logs a debug [message], optionally tagged with a source [name].
  static void d(String message, {String? name}) {
    if (!AppConfig.logEnabled) return;
    debugPrint(name == null ? message : '[$name] $message');
  }

  /// Logs an error [message] with optional [error] and [stackTrace].
  static void e(String message, {Object? error, StackTrace? stackTrace}) {
    if (!AppConfig.logEnabled) return;
    debugPrint('ERROR: $message${error != null ? ' — $error' : ''}');
    if (stackTrace != null) debugPrint('$stackTrace');
  }
}
