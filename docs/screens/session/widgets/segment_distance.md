# Segment Distance Widget

`RunWidgetType.segmentDistance` — shows the distance of the current segment,
e.g. `3 km`, or `750 m` for a partial last kilometer.

- **Value:** `session.currentSegmentDistanceDisplay`
  (`lib/models/running_session_display.dart`).
- **Default label:** `Next target distance`.
- **Style fields:** label size/color, value size/color. No status coloring.
- **Orientation:** label above value; label left / value right when placed
  1 row tall × full width (see [SCREEN_LAYOUTS.md](../../../SCREEN_LAYOUTS.md)).
- **Default layout:** row 1, left column, value size 32.
