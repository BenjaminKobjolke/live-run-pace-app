/// Distance display formatting shared by settings/start/session screens.
library;

/// Formats [value] with up to 3 decimals, trailing zeros trimmed
/// ("8", "8.5", "8.125").
String formatDistance(double value) =>
    value.toStringAsFixed(3).replaceFirst(RegExp(r'\.?0+$'), '');
