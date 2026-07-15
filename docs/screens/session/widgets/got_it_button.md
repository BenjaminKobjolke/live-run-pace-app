# GOT IT! Button Widget

`RunWidgetType.gotItButton` — the primary session button: completes the
current kilometer; on the last kilometer it reads **FINISH!** and ends the
session (with confirmation).

- **Action:** `RunScreenCallbacks.onNext` → `MainScreen._onNext` (screen
  flash, vibration, TTS announcement, autosave preserved).
- **Gating:** disabled during the ~1 s post-action debounce
  (`buttonNavigationDelay`).
- **Style fields:** only "Button size" (`valueFontSize`, clamped 12–24 for
  the text). Label/colors do not apply.
- **Default layout:** row 6, right column.

Deleting all control widgets is allowed — gestures can still complete
kilometers and abort (Settings → Gestures).
