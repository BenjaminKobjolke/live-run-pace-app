/// An action a main-screen gesture (single tap / double tap / long press) can
/// trigger. Assigned per gesture in Settings and resolved to a callback on the
/// run screen.
enum GestureAction {
  /// Do nothing.
  none('None'),

  /// Play/pause the AIMP music player via the native channel.
  toggleAimp('Toggle AIMP'),

  /// Mark the current kilometer complete and advance (last km asks to finish).
  completeKm('Complete km'),

  /// Step back one kilometer.
  previousKm('Previous km'),

  /// Pause the running session.
  pause('Pause'),

  /// Abort the running session (asks for confirmation).
  abort('Abort');

  const GestureAction(this.label);

  /// Human-readable label shown in the settings dropdown.
  final String label;
}
