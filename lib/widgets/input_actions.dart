import 'package:flutter/material.dart';

/// Cancel / OK action row used at the bottom of the input screens.
class InputActions extends StatelessWidget {
  /// Called when Cancel is tapped.
  final VoidCallback onCancel;

  /// Called when OK is tapped.
  final VoidCallback onOk;

  const InputActions({super.key, required this.onCancel, required this.onOk});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: onCancel,
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
          ),
        ),
        Expanded(
          child: TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            onPressed: onOk,
            child: const Text(
              'OK',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
