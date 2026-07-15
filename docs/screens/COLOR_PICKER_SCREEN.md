# Color Picker Screen

`lib/screens/color_picker_screen.dart` — full-screen color picker (240×432
friendly). **OK** pops the picked `Color`; **Cancel** / back pops null.

- **Preview bar** showing the color and its `#AARRGGBB` hex.
- **Preset swatches** (`presetSwatches` in
  `lib/services/run_widget_style.dart`).
- **Alpha/Red/Green/Blue sliders** (0–255) for custom colors.
- **Copy / Paste** — Copy puts the color on the system clipboard as
  `#AARRGGBB` (`lib/utils/color_hex.dart`); Paste applies a clipboard hex
  color (also accepts `RRGGBB`, treated as opaque) and shows a snackbar when
  the clipboard holds no valid color. This is how colors are reused across
  widgets — copy in one widget's picker, paste in another's.
