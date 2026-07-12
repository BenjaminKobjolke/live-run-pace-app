/// Central app configuration — no magic values scattered in code.
class AppConfig {
  AppConfig._();

  /// Single off switch for all logging routed through [AppLogger].
  // ponytail: one flag; wire to kReleaseMode if silencing release builds matters.
  static const bool logEnabled = true;
}
