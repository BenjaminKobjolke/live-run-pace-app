import 'package:flutter/material.dart';
import 'tap_value_box.dart';

/// Top row of the start screen: the run distance (tap to edit) and a settings
/// button.
class DistanceSettingsRow extends StatelessWidget {
  final String distanceText;
  final VoidCallback onDistanceTap;
  final VoidCallback onSettingsTap;

  const DistanceSettingsRow({
    super.key,
    required this.distanceText,
    required this.onDistanceTap,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Distance',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 4),
              TapValueBox(value: distanceText, onTap: onDistanceTap),
            ],
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: onSettingsTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.settings, color: Colors.white, size: 24),
          ),
        ),
      ],
    );
  }
}

/// "Paces" heading with side-by-side target and max pace boxes (tap to edit).
class PacesSection extends StatelessWidget {
  final String targetText;
  final String maxText;
  final VoidCallback onTargetTap;
  final VoidCallback onMaxTap;

  const PacesSection({
    super.key,
    required this.targetText,
    required this.maxText,
    required this.onTargetTap,
    required this.onMaxTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Paces',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _LabeledPaceBox(
                label: 'Target',
                value: targetText,
                onTap: onTargetTap,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _LabeledPaceBox(
                label: 'Max',
                value: maxText,
                onTap: onMaxTap,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A labelled, tappable pace value box.
class _LabeledPaceBox extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _LabeledPaceBox({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 4),
        TapValueBox(value: value, onTap: onTap),
      ],
    );
  }
}

/// Full-width START button.
class StartButton extends StatelessWidget {
  final VoidCallback onPressed;

  const StartButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        child: const Text(
          'START',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}
