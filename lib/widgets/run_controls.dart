import 'package:flutter/material.dart';

/// Bottom navigation controls for the running screen: a back button (previous
/// kilometer) and the primary GOT IT / FINISH button.
class RunControls extends StatelessWidget {
  /// Whether the buttons accept input (disabled briefly after each action).
  final bool enabled;

  /// Whether the previous-kilometer button is available.
  final bool canGoPrevious;

  /// Whether the primary button should read FINISH instead of GOT IT.
  final bool isLastKilometer;

  /// Called when the back (previous kilometer) button is tapped.
  final VoidCallback onPrevious;

  /// Called when the primary (next kilometer / finish) button is tapped.
  final VoidCallback onNext;

  const RunControls({
    super.key,
    required this.enabled,
    required this.canGoPrevious,
    required this.isLastKilometer,
    required this.onPrevious,
    required this.onNext,
  });

  ButtonStyle get _style => ElevatedButton.styleFrom(
    backgroundColor: Colors.transparent,
    foregroundColor: enabled ? Colors.white : Colors.white30,
    side: BorderSide(color: enabled ? Colors.white : Colors.white30, width: 2),
    padding: const EdgeInsets.symmetric(vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: ElevatedButton(
            onPressed: (enabled && canGoPrevious) ? onPrevious : null,
            style: _style,
            child: Icon(
              Icons.arrow_back,
              size: 20,
              color: enabled ? Colors.white : Colors.white30,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: ElevatedButton(
            onPressed: enabled ? onNext : null,
            style: _style,
            child: Text(
              isLastKilometer ? 'FINISH!' : 'GOT IT!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: enabled ? Colors.white : Colors.white30,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
