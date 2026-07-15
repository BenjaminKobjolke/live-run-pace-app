import 'package:flutter/material.dart';

/// Cancel / OK bottom row shared by the fullscreen pickers (color, number).
/// Cancel pops null; [onOk] pops the picked value.
class PickerBottomBar extends StatelessWidget {
  /// Called when OK is tapped; must pop the picked value.
  final VoidCallback onOk;

  const PickerBottomBar({super.key, required this.onOk});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
          ),
        ),
        Expanded(
          child: TextButton(
            onPressed: onOk,
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ),
      ],
    );
  }
}
