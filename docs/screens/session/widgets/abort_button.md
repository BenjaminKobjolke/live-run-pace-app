# Abort Button Widget

`RunWidgetType.abortButton` — aborts the session (✕ icon), always behind a
confirmation dialog.

- **Action:** `RunScreenCallbacks.onAbort` →
  `MainScreen._showAbortConfirmation`.
- **Gating:** none — always tappable (the dialog is the guard).
- **Style fields:** only "Button size" (`valueFontSize`, icon size clamped
  16–28).
- **Default layout:** row 1, right column (where the legacy header ✕ was).
