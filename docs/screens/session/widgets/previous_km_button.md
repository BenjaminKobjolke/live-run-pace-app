# Previous Km Button Widget

`RunWidgetType.previousKmButton` — steps back one kilometer (back-arrow
icon).

- **Action:** `RunScreenCallbacks.onPrevious` → `MainScreen._onPrevious`.
- **Gating:** disabled during the post-action debounce and on kilometer 1.
- **Style fields:** only "Button size" (`valueFontSize`, icon size clamped
  16–28).
- **Default layout:** row 6, left column.
