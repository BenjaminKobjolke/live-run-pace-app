import 'package:flutter/material.dart';

/// Full-width tappable row button used on the compact input screens and as
/// the option rows of the picker screen.
class MenuButton extends StatelessWidget {
  /// The button label.
  final String label;

  /// Called when the button is tapped.
  final VoidCallback onTap;

  const MenuButton({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}
