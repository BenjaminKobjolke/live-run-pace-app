import 'package:flutter/material.dart';
import 'blinking_cursor.dart';

/// Large centred read-out of a value (e.g. `10 km`, `5:30 / km`), optionally
/// tappable. Green-bordered box matching the app's input style.
class ValueDisplay extends StatelessWidget {
  /// The text to display.
  final String text;

  /// Optional suffix (e.g. the unit) rendered after the cursor, so the
  /// blinking cursor sits at the end of the edited value, not the unit.
  final String? suffix;

  /// Called when the box is tapped; `null` renders a plain display.
  final VoidCallback? onTap;

  /// Show a [BlinkingCursor] after [text] (for active keypad editing).
  final bool showCursor;

  const ValueDisplay({
    super.key,
    required this.text,
    this.suffix,
    this.onTap,
    this.showCursor = false,
  });

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: Colors.white,
      fontSize: 24,
      fontWeight: FontWeight.bold,
    );
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green),
        ),
        child: (showCursor || suffix != null)
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                      style: style,
                    ),
                  ),
                  if (showCursor) const BlinkingCursor(),
                  if (suffix != null) Text(' $suffix', style: style),
                ],
              )
            : Text(text, textAlign: TextAlign.center, style: style),
      ),
    );
  }
}
