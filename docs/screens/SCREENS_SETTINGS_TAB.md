# Screens Settings Tab

`lib/widgets/screens_settings_tab.dart` — the Settings → Screens tab. Lists
the configurable run screens (see [SCREEN_LAYOUTS.md](../SCREEN_LAYOUTS.md)).

- Each row: "Screen N — X widgets" with up/down reorder arrows (list order =
  page/swipe order) and delete (confirm dialog; the last remaining screen
  cannot be deleted).
- Tap a row → the **WYSIWYG screen editor**
  (`lib/screens/screen_editor_screen.dart`): the screen is rendered exactly
  like the live run screen (demo values, faint grid lines mark the cells,
  buttons are inert).
  - Tap an **empty cell** → add a widget there (the widget editor opens with
    that row/column prefilled).
  - Tap a **widget** → edit it ([WIDGET_EDITOR_SCREEN.md](WIDGET_EDITOR_SCREEN.md));
    deleting happens inside the widget editor.
  - Overlapping widgets are visible as painted; a tap always hits the
    **topmost** widget (paint order) — move or shrink it to reach one
    underneath.
  - Canvas: `lib/widgets/editable_screen_grid.dart`, rendering through the
    same `RunScreenGrid` as the live run screen (no second rendering path).
- "Add screen" appends an empty screen; "Reset to defaults" (confirm)
  restores the single legacy-replica screen.
- **Persistence:** every mutation saves immediately via
  `StorageService.saveScreenLayouts` — this tab is independent of the
  AppBar Save button (which only pops the TTS settings draft).
