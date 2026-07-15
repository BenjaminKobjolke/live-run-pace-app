import 'package:flutter/material.dart';
import 'blinking_cursor.dart';

/// The `MM : SS / unit` row shared by the compact pace screen and the pace
/// keypad screen: two tappable value boxes with a colon between and the unit
/// suffix after.
class PaceFieldsRow extends StatelessWidget {
  /// Minutes text (shown as `0` when empty).
  final String minutes;

  /// Seconds text (shown as `0` when empty).
  final String seconds;

  /// Display-only unit suffix, e.g. `'km'`.
  final String unit;

  /// Highlighted field: 0 = minutes, 1 = seconds, `null` = none.
  final int? activeField;

  /// Called with the field index (0/1) when a box is tapped.
  final ValueChanged<int>? onFieldTap;

  /// Show a [BlinkingCursor] after the active field's value.
  final bool showCursor;

  const PaceFieldsRow({
    super.key,
    required this.minutes,
    required this.seconds,
    required this.unit,
    this.activeField,
    this.onFieldTap,
    this.showCursor = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(child: _buildField(minutes, 'min', 0)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            ':',
            style: TextStyle(color: Colors.white, fontSize: 28),
          ),
        ),
        Expanded(child: _buildField(seconds, 'sec', 1)),
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            '/ $unit',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
      ],
    );
  }

  /// A tappable value box for one pace field; highlighted when active.
  Widget _buildField(String value, String label, int index) {
    final isActive = activeField == index;
    return GestureDetector(
      onTap: onFieldTap == null ? null : () => onFieldTap!(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? Colors.green : Colors.white24,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value.isEmpty ? '0' : value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isActive && showCursor) const BlinkingCursor(),
              ],
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
