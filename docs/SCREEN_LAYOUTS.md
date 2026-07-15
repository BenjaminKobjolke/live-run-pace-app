# Screen Layouts

The active-run UI is a user-configurable, swipeable set of screens ("pages"),
each holding widgets (stat/control tiles) on a fixed logical grid. Configured
in Settings → Screens; rendered by `RunScreenPager` in `MainScreen`.

## Grid

- **6 rows × 2 columns**, fixed (`RunScreenLayouts.gridRows` / `gridCols` in
  `lib/models/run_screen_layout.dart`).
- Cell sizes are **fractions of the available space** (`RunScreenGrid` uses a
  `LayoutBuilder`; `cellW = width / 2`, `cellH = height / 6`), so the same
  configuration works on any screen size.
- Tiles are absolutely positioned in a `Stack` (`lib/widgets/run_screen_grid.dart`).
  Overlapping tiles are allowed — they paint in list order (later on top);
  the WYSIWYG editor shows overlaps as painted, and its taps hit the topmost
  tile.
- Configured font sizes are **maxima**: tiles wrap text in
  `FittedBox(fit: BoxFit.scaleDown)`, so text shrinks to fit small cells but
  never enlarges.

## Orientation rule

Single home: `RunWidgetConfig.isHorizontal`.

- `rowSpan == 1 && colSpan == gridCols` (a flat full-width tile) → label
  left, value right.
- Anything else → label above value.
- Control (button) tiles ignore the rule — the button fills the cell.

## Data model (`lib/models/run_screen_layout.dart`)

- `RunScreenLayouts` — `screens: List<RunScreenConfig>` (page order).
- `RunScreenConfig` — `widgets: List<RunWidgetConfig>` (paint order). Screens
  have no name; they are displayed as "Screen N" by position.
- `RunWidgetConfig` — `type` (`RunWidgetType`), `row`, `col`, `rowSpan`,
  `colSpan`, `label` (null → type default), `labelFontSize`, `labelColor`,
  `valueFontSize`, `valueColor`, `autoColor`, `overTimeColor`. Colors are
  ARGB ints.

### Status colors

Types flagged `hasStatusColor` (currently only `timeLeft`) color their value
by `session.isOverTime`:

- `autoColor: true` (default) — built-in green (on schedule) / red (over time).
- `autoColor: false` — user-configured `valueColor` (on schedule) /
  `overTimeColor` (behind).

All styling resolves through `lib/services/run_widget_style.dart`
(`labelStyle` / `valueStyle` / `controlStyle`) — the seam a future theme
system plugs into.

## Persistence

SharedPreferences key `screen_layouts` (`StorageKeys.screenLayouts`),
`StorageService.loadScreenLayouts()` / `saveScreenLayouts()`. A missing,
corrupt, or empty configuration falls back to `RunScreenLayouts.defaults()` —
one screen replicating the legacy fixed layout, so existing users see no
change until they customize.

## Editing

Settings → Screens → tap a screen opens the **WYSIWYG editor**: the grid
rendered exactly like the run screen (demo values via
`lib/utils/demo_session.dart`, faint grid lines, inert buttons). Tap an
empty cell to add a widget there, tap a widget to edit or delete it; the
widget editor shows a live tile preview while adjusting. See
[screens/SCREENS_SETTINGS_TAB.md](screens/SCREENS_SETTINGS_TAB.md) and
[screens/WIDGET_EDITOR_SCREEN.md](screens/WIDGET_EDITOR_SCREEN.md).

## Widget events

Each `RunWidgetType` declares the events it subscribes to (`events`, a
`Set<RunEvent>`) — self-describing, no hardcoded lists in consumers.

- **`RunEvent.timeTick`** — fires once per second from
  `RunSessionController.tick` (a `ValueNotifier<DateTime>` driven by a 1 s
  timer; frozen while paused or backgrounded). Subscribed types:
  `elapsedTime`, `timeLeft`, `finishTime`, `currentPace`. Their `RunStatTile`
  wraps itself in a `ListenableBuilder` on the tick, so only those tiles
  rebuild each second.
- **No subscription needed for km/session changes** — km advance, pause,
  finish call `notifyListeners()` on the controller, which rebuilds the whole
  page (covers `segmentDistance`, `nextTargetTime`, `averagePace`, buttons).
- **Only the visible screen updates**: the pager's `PageView` has zero cache
  extent, so off-screen pages are not built at all — nothing subscribes,
  nothing ticks (pinned by `test/run_screen_pager_test.dart`; don't add
  keep-alive or `allowImplicitScrolling` to `RunScreenPager`).
- Previews (WYSIWYG editor, widget editor) pass no tick — static demo data.

## Widget types

See `docs/screens/session/widgets/` — one file per type. Stat types read a
`RunningSession` display getter via `runWidgetValue`
(`lib/services/run_widget_values.dart`); control types map to
`RunScreenCallbacks` actions in `RunControlTile`.

## Adding a new widget type (checklist)

1. Add the enum value in `lib/models/run_widget_type.dart` with `label`,
   `defaultLabel` (or `isControl: true`), flags, and the `events` it
   subscribes to (`{RunEvent.timeTick}` if its value changes every second).
2. Add its case to the exhaustive switch in
   `lib/services/run_widget_values.dart` (the compiler forces this). For a
   control, also handle it in `lib/widgets/run_control_tile.dart`.
3. Add its doc file under `docs/screens/session/widgets/`.
4. Done. Serialization is generic (enum name + shared style fields), so
   **export/import needs no changes**. Older app versions importing a file
   that contains the new type simply **skip** that widget entry
   (`RunWidgetConfig.tryFromJson` returns null for unknown names); the rest
   of the screen imports fine. The `run_widget_values_test.dart` loop over
   `RunWidgetType.values` fails CI if a type is half-wired.
