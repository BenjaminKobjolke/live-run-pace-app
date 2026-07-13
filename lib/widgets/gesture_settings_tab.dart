import 'package:flutter/material.dart';
import '../models/gesture_action.dart';
import 'setting_controls.dart';

/// Gesture settings tab for assigning main-screen actions to gestures.
class GestureSettingsTab extends StatelessWidget {
  /// Action for a single tap.
  final GestureAction singleTapAction;

  /// Action for a double tap.
  final GestureAction doubleTapAction;

  /// Action for a long press.
  final GestureAction longPressAction;

  /// Whether button navigation should be delayed.
  final bool buttonNavigationDelay;

  /// Updates the single-tap action.
  final ValueChanged<GestureAction> onSingleTapChanged;

  /// Updates the double-tap action.
  final ValueChanged<GestureAction> onDoubleTapChanged;

  /// Updates the long-press action.
  final ValueChanged<GestureAction> onLongPressChanged;

  /// Updates the button-navigation delay flag.
  final ValueChanged<bool> onButtonNavigationDelayChanged;

  /// Creates a gesture settings tab.
  const GestureSettingsTab({
    super.key,
    required this.singleTapAction,
    required this.doubleTapAction,
    required this.longPressAction,
    required this.buttonNavigationDelay,
    required this.onSingleTapChanged,
    required this.onDoubleTapChanged,
    required this.onLongPressChanged,
    required this.onButtonNavigationDelayChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _gestureDropdown('Single tap', singleTapAction, onSingleTapChanged),
          const SizedBox(height: 20),
          _gestureDropdown('Double tap', doubleTapAction, onDoubleTapChanged),
          const SizedBox(height: 20),
          _gestureDropdown('Long press', longPressAction, onLongPressChanged),
          const SizedBox(height: 20),
          SettingSwitch(
            label: 'Delay button navigation',
            value: buttonNavigationDelay,
            onChanged: onButtonNavigationDelayChanged,
          ),
        ],
      ),
    );
  }

  Widget _gestureDropdown(
    String label,
    GestureAction value,
    ValueChanged<GestureAction> onChanged,
  ) {
    return SettingDropdown<GestureAction>(
      label: label,
      value: value,
      items: GestureAction.values,
      itemLabel: (action) => action.label,
      onChanged: (action) {
        if (action != null) onChanged(action);
      },
    );
  }
}
