/// Events a run widget can subscribe to (declared per [RunWidgetType]).
///
/// Delivery: [timeTick] fires every second from the session controller's
/// tick Listenable, and only the subscribed tiles on the **visible** page
/// rebuild. Kilometer/session changes need no subscription — they arrive via
/// the controller's ChangeNotifier as a full-page rebuild.
enum RunEvent {
  /// Fires once per second while the session runs (frozen while paused or
  /// backgrounded).
  timeTick,
}

/// The kinds of tiles a user can place on a configurable run screen.
///
/// Adding a new type: add the constant here (declaring the [RunEvent]s it
/// subscribes to), add its case to `runWidgetValue` (exhaustive switch — the
/// compiler enforces it) and, for controls, to `RunControlTile`.
/// Serialization is generic (enum name), so import/export needs no changes;
/// older app versions skip unknown names on import. See
/// docs/SCREEN_LAYOUTS.md.
enum RunWidgetType {
  /// Distance of the current segment (e.g. "3 km" / "750 m").
  segmentDistance(label: 'Segment distance', defaultLabel: 'Next target distance'),

  /// Elapsed session time.
  elapsedTime(
    label: 'Elapsed time',
    defaultLabel: 'Current',
    events: {RunEvent.timeTick},
  ),

  /// Target time for the next kilometer.
  nextTargetTime(label: 'Next target time', defaultLabel: 'Next target'),

  /// Time left for the current kilometer (status-colored).
  timeLeft(
    label: 'Time left',
    defaultLabel: 'Time left',
    hasStatusColor: true,
    events: {RunEvent.timeTick},
  ),

  /// Projected finish time.
  finishTime(
    label: 'Finish time',
    defaultLabel: 'Finish time',
    events: {RunEvent.timeTick},
  ),

  /// Average pace of the current run so far.
  currentPace(
    label: 'Current pace',
    defaultLabel: 'Current pace',
    events: {RunEvent.timeTick},
  ),

  /// Average pace over completed kilometers.
  averagePace(label: 'Average pace', defaultLabel: 'Average pace'),

  /// The GOT IT! / FINISH! primary button.
  gotItButton(label: 'GOT IT! button', isControl: true),

  /// Steps back one kilometer.
  previousKmButton(label: 'Previous km button', isControl: true),

  /// Aborts the session (with confirmation).
  abortButton(label: 'Abort button', isControl: true);

  const RunWidgetType({
    required this.label,
    this.defaultLabel = '',
    this.isControl = false,
    this.hasStatusColor = false,
    this.events = const {},
  });

  /// Name shown in the widget editor's type dropdown.
  final String label;

  /// Tile label used when the user has not overridden it. Empty for controls.
  final String defaultLabel;

  /// True for button tiles (no label/value styling, render as a button).
  final bool isControl;

  /// True when the value color follows the pace status (over time → red).
  final bool hasStatusColor;

  /// The [RunEvent]s this widget subscribes to; tiles rebuild when a
  /// subscribed event fires. Empty for values that only change on km/session
  /// actions (those repaint via the controller's ChangeNotifier).
  final Set<RunEvent> events;
}
