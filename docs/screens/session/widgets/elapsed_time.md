# Elapsed Time Widget

`RunWidgetType.elapsedTime` — the running session clock (frozen while
paused).

- **Value:** `session.currentTimeDisplay` (`h:mm:ss`, hours omitted when 0).
- **Updates:** every second via the `timeTick` event (visible screen only).
- **Default label:** `Current`.
- **Style fields:** label size/color, value size/color. No status coloring.
- **Orientation:** label above value; label left / value right when placed
  1 row tall × full width.
- **Default layout:** row 2, left column, value size 24.
