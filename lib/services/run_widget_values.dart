import '../models/run_widget_type.dart';
import '../models/running_session.dart';

/// Resolves the display text of a run-screen tile from the session.
///
/// One exhaustive switch onto the existing [RunningSession] display getters —
/// the compiler forces a case for every new [RunWidgetType]. Control tiles
/// have no value and return an empty string.
String runWidgetValue(RunWidgetType type, RunningSession session) {
  switch (type) {
    case RunWidgetType.segmentDistance:
      return session.currentSegmentDistanceDisplay;
    case RunWidgetType.elapsedTime:
      return session.currentTimeDisplay;
    case RunWidgetType.nextTargetTime:
      return session.nextTargetTimeDisplay;
    case RunWidgetType.timeLeft:
      return session.timeLeftDisplay;
    case RunWidgetType.finishTime:
      return session.finishTimeDisplay;
    case RunWidgetType.currentPace:
      return session.currentPaceDisplay;
    case RunWidgetType.averagePace:
      return session.averagePaceDisplay;
    case RunWidgetType.gotItButton:
    case RunWidgetType.previousKmButton:
    case RunWidgetType.abortButton:
      return '';
  }
}
