import 'package:flutter/material.dart';
import '../models/run_screen_layout.dart';
import '../models/running_session.dart';

/// Central style resolution for run-screen tiles — the theme seam.
///
/// Every tile reads its text and button styles exclusively through these
/// functions, so a future theme system only has to replace this file's
/// internals.

/// Text style of a tile label.
TextStyle labelStyle(RunWidgetConfig config) {
  return TextStyle(
    color: Color(config.labelColor),
    fontSize: config.labelFontSize,
  );
}

/// Text style of a tile value. For status-colored types the color follows
/// [RunningSession.isOverTime]: the built-in green/red pair when
/// [RunWidgetConfig.autoColor] is on, the user's valueColor/overTimeColor
/// pair when it is off.
TextStyle valueStyle(RunWidgetConfig config, RunningSession session) {
  Color color;
  if (config.type.hasStatusColor) {
    if (config.autoColor) {
      color = session.isOverTime ? Colors.red : Colors.green;
    } else {
      color = Color(session.isOverTime ? config.overTimeColor : config.valueColor);
    }
  } else {
    color = Color(config.valueColor);
  }
  return TextStyle(
    color: color,
    fontSize: config.valueFontSize,
    fontWeight: FontWeight.bold,
  );
}

/// Shared outline style for control tiles (moved from the retired
/// RunControls widget so button visuals stay identical).
ButtonStyle controlStyle(bool enabled) {
  return ElevatedButton.styleFrom(
    backgroundColor: Colors.transparent,
    foregroundColor: enabled ? Colors.white : Colors.white30,
    side: BorderSide(color: enabled ? Colors.white : Colors.white30, width: 2),
    padding: const EdgeInsets.symmetric(vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
  );
}

/// Preset swatches offered by the color picker grid.
const List<Color> presetSwatches = [
  Colors.white,
  Colors.white70,
  Colors.grey,
  Colors.red,
  Colors.green,
  Colors.blue,
  Colors.yellow,
  Colors.orange,
  Colors.cyan,
  Colors.purple,
];
