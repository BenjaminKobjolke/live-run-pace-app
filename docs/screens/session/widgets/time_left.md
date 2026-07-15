# Time Left Widget

`RunWidgetType.timeLeft` — time remaining for the current kilometer, with a
`-` prefix when over.

- **Value:** `session.timeLeftDisplay`.
- **Updates:** every second via the `timeTick` event (visible screen only) —
  the status color flips green→red live.
- **Default label:** `Time left`.
- **Status coloring (the only type with it today):** value color follows
  `session.isOverTime`:
  - **Auto colors** on (default): green on schedule, red over time — the
    legacy behavior.
  - Auto colors off: user-configured "On schedule color" (`valueColor`) and
    "Behind color" (`overTimeColor`).
- **Orientation:** label above value; label left / value right when placed
  1 row tall × full width.
- **Default layout:** rows 3–4, both columns (2×2), value size 42, auto
  colors on.
