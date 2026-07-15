import 'package:flutter/material.dart';
import '../models/run_screen_layout.dart';
import '../models/run_widget_type.dart';
import '../services/run_widget_style.dart';
import 'run_screen_callbacks.dart';

/// A button cell of a run screen grid.
///
/// Gating matches the retired fixed controls: GOT IT!/back respect the
/// post-action debounce ([RunScreenCallbacks.buttonsEnabled]); abort is
/// always available (its handler confirms). [RunWidgetConfig.valueFontSize]
/// sets the text/icon size.
class RunControlTile extends StatelessWidget {
  /// Placement and sizing of this tile (must be a control type).
  final RunWidgetConfig config;

  /// Actions and button state from MainScreen.
  final RunScreenCallbacks callbacks;

  const RunControlTile({
    super.key,
    required this.config,
    required this.callbacks,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = _enabled;
    final size = config.valueFontSize;

    return Padding(
      padding: const EdgeInsets.all(4),
      child: ElevatedButton(
        onPressed: enabled ? _onPressed : null,
        style: controlStyle(enabled),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: _child(enabled, size),
        ),
      ),
    );
  }

  bool get _enabled {
    switch (config.type) {
      case RunWidgetType.gotItButton:
        return callbacks.buttonsEnabled;
      case RunWidgetType.previousKmButton:
        return callbacks.buttonsEnabled && callbacks.canGoPrevious;
      default:
        return true;
    }
  }

  VoidCallback get _onPressed {
    switch (config.type) {
      case RunWidgetType.gotItButton:
        return callbacks.onNext;
      case RunWidgetType.previousKmButton:
        return callbacks.onPrevious;
      default:
        return callbacks.onAbort;
    }
  }

  Widget _child(bool enabled, double size) {
    final color = enabled ? Colors.white : Colors.white30;
    switch (config.type) {
      case RunWidgetType.gotItButton:
        return Text(
          callbacks.isLastKilometer ? 'FINISH!' : 'GOT IT!',
          style: TextStyle(
            fontSize: size.clamp(12, 24),
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: color,
          ),
        );
      case RunWidgetType.previousKmButton:
        return Icon(Icons.arrow_back, size: size.clamp(16, 28), color: color);
      default:
        return Icon(Icons.close, size: size.clamp(16, 28), color: color);
    }
  }
}
