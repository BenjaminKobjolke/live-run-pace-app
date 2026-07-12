import 'package:flutter/material.dart';

/// Top bar of the running screen: the "Next target distance" label and the
/// abort (X) button.
class RunHeader extends StatelessWidget {
  /// Called when the abort button is tapped.
  final VoidCallback onAbort;

  const RunHeader({super.key, required this.onAbort});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(width: 20),
        const Text(
          'Next target distance',
          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w300),
        ),
        GestureDetector(
          onTap: onAbort,
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.close, color: Colors.black, size: 14),
          ),
        ),
      ],
    );
  }
}
