# Current Pace Widget

`RunWidgetType.currentPace` — average min/km pace of the run so far
(`--:--` on the first kilometer).

- **Value:** `session.currentPaceDisplay`.
- **Updates:** every second via the `timeTick` event (visible screen only).
- **Default label:** `Current pace`.
- **Style fields:** label size/color, value size/color. No status coloring.
- **Orientation:** label above value; label left / value right when placed
  1 row tall × full width.
- Not part of the default layout — add it via Settings → Screens.
