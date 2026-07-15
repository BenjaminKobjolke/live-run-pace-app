import 'package:flutter/material.dart';
import '../models/run_widget_type.dart';
import 'number_picker_screen.dart';
import 'option_picker_screen.dart';

/// Fullscreen-picker navigation used by the widget editor's
/// `SettingPickerRow`s. Split out to keep the editor under the file-size cap;
/// every function pushes a picker and returns the picked value (null =
/// cancelled).

/// Fullscreen list picker over [min]..[max]; [display] renders each entry
/// (row/column show 1-based numbers).
Future<int?> pickNumberOption(
  BuildContext context,
  String title,
  int min,
  int max,
  String Function(int) display,
) {
  return Navigator.of(context).push<int>(
    MaterialPageRoute(
      builder: (context) => OptionPickerScreen<int>(
        title: title,
        options: [
          for (var i = min; i <= max; i++)
            PickerOption(label: display(i), value: i),
        ],
      ),
    ),
  );
}

/// Fullscreen slide-up/down number picker for font/button sizes.
Future<int?> pickSize(
  BuildContext context,
  String title,
  double value,
  int min,
  int max,
) {
  return Navigator.of(context).push<int>(
    MaterialPageRoute(
      builder: (context) => NumberPickerScreen(
        title: title,
        value: value.round(),
        min: min,
        max: max,
      ),
    ),
  );
}

/// Fullscreen picker over all widget types.
Future<RunWidgetType?> pickWidgetType(BuildContext context) {
  return Navigator.of(context).push<RunWidgetType>(
    MaterialPageRoute(
      builder: (context) => OptionPickerScreen<RunWidgetType>(
        title: 'Widget type',
        options: [
          for (final type in RunWidgetType.values)
            PickerOption(label: type.label, value: type),
        ],
      ),
    ),
  );
}
