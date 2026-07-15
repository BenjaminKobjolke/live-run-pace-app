/// Distance display formatting shared by settings/start/session screens.
library;

/// Formats [value] with up to 6 decimals, trailing zeros trimmed
/// ("8", "8.5", "42.12234") — enough to keep any hand-typed distance
/// while capping float artifacts.
String formatDistance(double value) =>
    value.toStringAsFixed(6).replaceFirst(RegExp(r'\.?0+$'), '');
