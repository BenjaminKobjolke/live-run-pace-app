# Finish Time Widget

`RunWidgetType.finishTime` — projected total time at the finish, from
elapsed time plus target pace × remaining distance.

- **Value:** `session.finishTimeDisplay`.
- **Updates:** every second via the `timeTick` event (visible screen only).
- **Default label:** `Finish time`.
- **Style fields:** label size/color, value size/color. No status coloring.
- **Orientation:** label above value; label left / value right when placed
  1 row tall × full width.
- **Default layout:** row 5, full width (1×2) → renders horizontally,
  value size 32.
