import 'package:flutter/material.dart';

/// A bordered, tappable box showing a large centered [value] — used for the
/// distance and pace fields on the start screen.
class TapValueBox extends StatelessWidget {
  /// The value text to display.
  final String value;

  /// Called when the box is tapped (typically opens an edit dialog).
  final VoidCallback onTap;

  const TapValueBox({super.key, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
