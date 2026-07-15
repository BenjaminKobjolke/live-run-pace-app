import 'package:flutter/material.dart';
import '../models/run_screen_layout.dart';
import '../models/running_session.dart';
import 'run_screen_callbacks.dart';
import 'run_screen_grid.dart';

/// Reports a tap on grid cell ([row], [col]). [widgetIndex] is the index of
/// the topmost widget covering that cell, or null for an empty cell.
typedef CellTapCallback = void Function(int row, int col, int? widgetIndex);

/// The WYSIWYG canvas of the screen editor: renders a [RunScreenConfig]
/// exactly like the run screen (via [RunScreenGrid] with demo data), plus
/// faint grid lines so empty cells are visible. Tiles are inert
/// ([AbsorbPointer]); every tap is translated to a cell and reported through
/// [onCellTap]. Overlapping widgets resolve to the topmost (paint order).
class EditableScreenGrid extends StatelessWidget {
  /// The screen being edited.
  final RunScreenConfig screen;

  /// Demo session feeding the stat tiles.
  final RunningSession session;

  /// Invoked for every tap with the cell and the hit widget (null = empty).
  final CellTapCallback onCellTap;

  const EditableScreenGrid({
    super.key,
    required this.screen,
    required this.session,
    required this.onCellTap,
  });

  /// Index of the topmost widget covering ([row], [col]), or null.
  /// List order = paint order, so the last match wins.
  int? _hitWidget(int row, int col) {
    for (var i = screen.widgets.length - 1; i >= 0; i--) {
      final w = screen.widgets[i];
      final inRows = row >= w.row && row < w.row + w.rowSpan;
      final inCols = col >= w.col && col < w.col + w.colSpan;
      if (inRows && inCols) return i;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellW = constraints.maxWidth / RunScreenLayouts.gridCols;
        final cellH = constraints.maxHeight / RunScreenLayouts.gridRows;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) {
            final col = (details.localPosition.dx / cellW)
                .floor()
                .clamp(0, RunScreenLayouts.gridCols - 1);
            final row = (details.localPosition.dy / cellH)
                .floor()
                .clamp(0, RunScreenLayouts.gridRows - 1);
            onCellTap(row, col, _hitWidget(row, col));
          },
          child: Stack(
            children: [
              // Editor-only grid lines; the real run screen has none.
              for (var r = 0; r < RunScreenLayouts.gridRows; r++)
                for (var c = 0; c < RunScreenLayouts.gridCols; c++)
                  Positioned(
                    left: c * cellW,
                    top: r * cellH,
                    width: cellW,
                    height: cellH,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white12, width: 0.5),
                      ),
                    ),
                  ),
              // The tiles, rendered exactly like the run screen but inert.
              Positioned.fill(
                child: AbsorbPointer(
                  child: RunScreenGrid(
                    screen: screen,
                    session: session,
                    callbacks: RunScreenCallbacks.noop(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
