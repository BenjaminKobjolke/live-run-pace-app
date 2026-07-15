# Widget Editor Screen

`lib/screens/widget_editor_screen.dart` — edits one `RunWidgetConfig`.
AppBar **Save** pops the edited config to the WYSIWYG screen editor; back
pops null (no change).

## Live preview

The top of the form shows the tile rendered with demo values
(`demoSession()`, `lib/utils/demo_session.dart`), sized proportionally to
the configured span (height capped so tall spans don't crowd the form).
Every field change updates it instantly — type, spans (including the
horizontal/vertical orientation flip), label, sizes, and colors. Rendering
goes through the shared `runTileFor` (`lib/widgets/run_screen_grid.dart`),
so the preview can never diverge from the run screen. Status-colored types
preview the on-schedule state.

## Fields

Every field is a `SettingPickerRow` (label + current value + chevron) that
opens a **fullscreen picker** — no inline dropdowns or sliders on the 240×432
screen:

- **Type** — [Option Picker](OPTION_PICKER_SCREEN.md) over all
  `RunWidgetType`s.
- **Row**, **Column** (shown 1-based), **Rows filled**, **Columns filled** —
  Option Pickers; spans are clamped so the tile always stays inside the 6×2
  grid (moving the position re-clamps the spans). Row/column arrive
  prefilled from the cell tapped in the screen editor.
- Stat types additionally:
  - **Label** text field (empty = the type's default label),
  - **Label size** (8–24) and **Value size** (12–72) — each opens the
    [Number Picker](NUMBER_PICKER_SCREEN.md) (slide up/down, big number),
  - **Label color**,
  - value color section:
    - status-colored types (`time_left`): **Auto colors** switch (default
      on). Off reveals **On schedule color** + **Behind color**.
    - other types: a single **Value color** row.
- Control types: only placement + **Button size** (Number Picker, 12–72).
- **Delete widget** (red, bottom) — shown only when editing an existing
  widget (the screen editor passes an `onDelete` callback; adding passes
  none). Confirms via `showConfirmDialog`, then removes the widget and
  closes the editor.

Color rows use `ColorSettingRow` (`lib/widgets/setting_controls.dart`) →
[COLOR_PICKER_SCREEN.md](COLOR_PICKER_SCREEN.md).
