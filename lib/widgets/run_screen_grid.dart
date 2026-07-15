import 'package:flutter/material.dart';
import '../models/run_screen_layout.dart';
import '../models/running_session.dart';
import 'run_control_tile.dart';
import 'run_screen_callbacks.dart';
import 'run_stat_tile.dart';

/// The tile widget for one [RunWidgetConfig] — a button for control types,
/// a stat tile otherwise. Shared by [RunScreenGrid] and the widget-editor
/// live preview so the type dispatch exists once. [tick] is the 1 s
/// time-tick source; omit for static previews.
Widget runTileFor(
  RunWidgetConfig config,
  RunningSession session,
  RunScreenCallbacks callbacks, {
  Listenable? tick,
}) {
  return config.type.isControl
      ? RunControlTile(config: config, callbacks: callbacks)
      : RunStatTile(config: config, session: session, tick: tick);
}

/// Lays one [RunScreenConfig] out on the fixed logical grid.
///
/// Cell sizes are fractions of the available space, so the same
/// configuration works on any screen size. Tiles are absolutely positioned
/// (a Stack, not a GridView): spans are trivial, nothing scrolls, and
/// overlapping tiles simply paint in list order.
class RunScreenGrid extends StatelessWidget {
  /// The screen to render.
  final RunScreenConfig screen;

  /// The live session tiles read from.
  final RunningSession session;

  /// Actions and button state for control tiles.
  final RunScreenCallbacks callbacks;

  /// The 1 s time-tick source for tick-subscribed tiles; null in previews.
  final Listenable? tick;

  const RunScreenGrid({
    super.key,
    required this.screen,
    required this.session,
    required this.callbacks,
    this.tick,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellW = constraints.maxWidth / RunScreenLayouts.gridCols;
        final cellH = constraints.maxHeight / RunScreenLayouts.gridRows;

        return Stack(
          children: [
            for (final config in screen.widgets)
              Positioned(
                left: config.col * cellW,
                top: config.row * cellH,
                width: config.colSpan * cellW,
                height: config.rowSpan * cellH,
                child: runTileFor(config, session, callbacks, tick: tick),
              ),
          ],
        );
      },
    );
  }
}
