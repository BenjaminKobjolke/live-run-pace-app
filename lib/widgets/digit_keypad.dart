import 'package:flutter/material.dart';

/// On-screen 3x4 numeric keypad — digits, an optional decimal separator, and
/// backspace. Owns no value: the parent holds the edited string and reacts to
/// the callbacks. Replaces the OS keyboard for the small-screen distance/pace
/// inputs where the system keyboard covers the UI.
class DigitKeypad extends StatelessWidget {
  /// Called with the tapped digit character (`'0'`..`'9'`).
  final ValueChanged<String> onDigit;

  /// Called when the decimal separator (`.`) is tapped. Only fires when
  /// [allowDecimal] is true.
  final VoidCallback onDecimal;

  /// Called when the backspace key is tapped.
  final VoidCallback onBackspace;

  /// When false the `.` key is rendered greyed-out and does nothing — used for
  /// integer-only fields (pace minutes/seconds).
  final bool allowDecimal;

  const DigitKeypad({
    super.key,
    required this.onDigit,
    required this.onDecimal,
    required this.onBackspace,
    this.allowDecimal = true,
  });

  @override
  Widget build(BuildContext context) {
    // Grid layout, row by row. The last row carries the decimal + backspace.
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['.', '0', '<'],
    ];

    return Column(
      children: rows.map((row) {
        return Expanded(
          child: Row(
            children: row.map(_buildKey).toList(),
          ),
        );
      }).toList(),
    );
  }

  /// Builds a single keypad cell for [label] (`'<'` = backspace, `'.'` = decimal).
  Widget _buildKey(String label) {
    final isDecimal = label == '.';
    final isBackspace = label == '<';
    final disabled = isDecimal && !allowDecimal;

    VoidCallback? onTap;
    if (isBackspace) {
      onTap = onBackspace;
    } else if (isDecimal) {
      onTap = disabled ? null : onDecimal;
    } else {
      onTap = () => onDigit(label);
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Material(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
              child: isBackspace
                  ? const Icon(Icons.backspace, color: Colors.white, size: 24)
                  : Text(
                      label,
                      style: TextStyle(
                        color: disabled ? Colors.white24 : Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
