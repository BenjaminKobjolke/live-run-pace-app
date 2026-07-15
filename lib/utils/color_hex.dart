import 'dart:ui';

/// Hex conversion for colors, used by the color picker's Copy/Paste.
///
/// Format is `#AARRGGBB`; parsing also accepts a missing `#` and 6-digit
/// `RRGGBB` (treated as fully opaque).

/// Formats [color] as `#AARRGGBB`.
String colorToHex(Color color) {
  final argb = color.toARGB32();
  return '#${argb.toRadixString(16).toUpperCase().padLeft(8, '0')}';
}

/// Parses `#AARRGGBB` / `AARRGGBB` / `#RRGGBB` / `RRGGBB`; null if invalid.
Color? tryParseHexColor(String input) {
  var hex = input.trim();
  if (hex.startsWith('#')) hex = hex.substring(1);
  if (hex.length == 6) hex = 'FF$hex';
  if (hex.length != 8) return null;
  final value = int.tryParse(hex, radix: 16);
  return value == null ? null : Color(value);
}
