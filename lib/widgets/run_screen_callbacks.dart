import 'package:flutter/material.dart';

/// Session actions and button state handed to run-screen control tiles as a
/// single value object (instead of a per-callback parameter swarm). Built by
/// MainScreen on every rebuild.
class RunScreenCallbacks {
  /// Complete the current km — the GOT IT! / FINISH! action.
  final VoidCallback onNext;

  /// Step back one kilometer.
  final VoidCallback onPrevious;

  /// Abort the session (shows its own confirmation).
  final VoidCallback onAbort;

  /// False during the brief post-action debounce window.
  final bool buttonsEnabled;

  /// Whether stepping back is currently possible (km > 1).
  final bool canGoPrevious;

  /// Whether the primary button reads FINISH! instead of GOT IT!.
  final bool isLastKilometer;

  const RunScreenCallbacks({
    required this.onNext,
    required this.onPrevious,
    required this.onAbort,
    required this.buttonsEnabled,
    required this.canGoPrevious,
    required this.isLastKilometer,
  });

  /// Inert callbacks for previews (WYSIWYG editor, widget-editor preview):
  /// buttons look enabled but do nothing.
  factory RunScreenCallbacks.noop() => RunScreenCallbacks(
        onNext: () {},
        onPrevious: () {},
        onAbort: () {},
        buttonsEnabled: true,
        canGoPrevious: true,
        isLastKilometer: false,
      );
}
