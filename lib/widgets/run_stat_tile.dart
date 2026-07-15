import 'package:flutter/material.dart';
import '../models/run_screen_layout.dart';
import '../models/run_widget_type.dart';
import '../models/running_session.dart';
import '../services/run_widget_style.dart';
import '../services/run_widget_values.dart';

/// One stat cell of a run screen grid.
///
/// Orientation follows [RunWidgetConfig.isHorizontal]: flat full-width tiles
/// put the label left and the value right; all others stack the label above
/// the value. Configured font sizes are maxima — [FittedBox] with
/// [BoxFit.scaleDown] shrinks text on small screens but never enlarges it.
///
/// Types that declare [RunEvent.timeTick] re-read their session value on
/// every fire of [tick]; other types render once per parent rebuild.
class RunStatTile extends StatelessWidget {
  /// Placement and styling of this tile.
  final RunWidgetConfig config;

  /// The live session the value is read from.
  final RunningSession session;

  /// The 1 s time-tick event source; null in static previews (editor).
  final Listenable? tick;

  const RunStatTile({
    super.key,
    required this.config,
    required this.session,
    this.tick,
  });

  @override
  Widget build(BuildContext context) {
    final tickSource = tick;
    if (tickSource != null &&
        config.type.events.contains(RunEvent.timeTick)) {
      return ListenableBuilder(
        listenable: tickSource,
        builder: (context, _) => _body(),
      );
    }
    return _body();
  }

  Widget _body() {
    final label = Text(config.effectiveLabel, style: labelStyle(config));
    final value = Text(
      runWidgetValue(config.type, session),
      style: valueStyle(config, session),
    );

    if (config.isHorizontal) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            FittedBox(fit: BoxFit.scaleDown, child: label),
            const SizedBox(width: 8),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: FittedBox(fit: BoxFit.scaleDown, child: value),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(fit: BoxFit.scaleDown, child: label),
          Expanded(
            child: Center(
              child: FittedBox(fit: BoxFit.scaleDown, child: value),
            ),
          ),
        ],
      ),
    );
  }
}
