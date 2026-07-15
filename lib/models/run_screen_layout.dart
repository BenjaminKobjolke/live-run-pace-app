import 'run_widget_type.dart';

/// Placement and styling of one tile on a run screen grid.
///
/// Colors are stored as ARGB ints so the model stays free of Flutter imports
/// and serializes trivially. All styling is resolved centrally in
/// `run_widget_style.dart` (the future theme seam).
class RunWidgetConfig {
  /// What the tile shows or does.
  final RunWidgetType type;

  /// Top-left grid cell (0-based).
  final int row;

  /// Left grid column (0-based).
  final int col;

  /// Number of grid rows the tile covers.
  final int rowSpan;

  /// Number of grid columns the tile covers.
  final int colSpan;

  /// User label override; null falls back to [RunWidgetType.defaultLabel].
  final String? label;

  /// Label text size (a maximum — tiles shrink text to fit).
  final double labelFontSize;

  /// Label color as ARGB int.
  final int labelColor;

  /// Value text size (a maximum — tiles shrink text to fit).
  final double valueFontSize;

  /// Value color as ARGB int (on-schedule color for status-colored types).
  final int valueColor;

  /// For [RunWidgetType.hasStatusColor] types: true uses the built-in
  /// green/red pace coloring; false uses [valueColor] / [overTimeColor].
  final bool autoColor;

  /// Value color while over time, when [autoColor] is off. ARGB int.
  final int overTimeColor;

  const RunWidgetConfig({
    required this.type,
    this.row = 0,
    this.col = 0,
    this.rowSpan = 1,
    this.colSpan = 1,
    this.label,
    this.labelFontSize = 12,
    this.labelColor = 0xB3FFFFFF,
    this.valueFontSize = 32,
    this.valueColor = 0xFFFFFFFF,
    this.autoColor = true,
    this.overTimeColor = 0xFFF44336,
  });

  /// Label shown on the tile.
  String get effectiveLabel => label ?? type.defaultLabel;

  /// Flat full-width stat tiles render label left / value right; everything
  /// else stacks label above value. Single home of the orientation rule.
  bool get isHorizontal =>
      rowSpan == 1 && colSpan == RunScreenLayouts.gridCols;

  /// Parses a widget entry, or returns null for an unknown [type] name so the
  /// caller can skip entries written by newer app versions. Placement is
  /// clamped into the grid; missing fields keep their defaults.
  static RunWidgetConfig? tryFromJson(Map<String, dynamic> json) {
    final type = RunWidgetType.values.asNameMap()[json['type']];
    if (type == null) return null;

    const def = RunWidgetConfig(type: RunWidgetType.timeLeft);
    final row = _clamp(json['row'], 0, RunScreenLayouts.gridRows - 1, def.row);
    final col = _clamp(json['col'], 0, RunScreenLayouts.gridCols - 1, def.col);
    return RunWidgetConfig(
      type: type,
      row: row,
      col: col,
      rowSpan: _clamp(
          json['rowSpan'], 1, RunScreenLayouts.gridRows - row, def.rowSpan),
      colSpan: _clamp(
          json['colSpan'], 1, RunScreenLayouts.gridCols - col, def.colSpan),
      label: json['label'] as String?,
      labelFontSize:
          (json['labelFontSize'] as num?)?.toDouble() ?? def.labelFontSize,
      labelColor: json['labelColor'] as int? ?? def.labelColor,
      valueFontSize:
          (json['valueFontSize'] as num?)?.toDouble() ?? def.valueFontSize,
      valueColor: json['valueColor'] as int? ?? def.valueColor,
      autoColor: json['autoColor'] as bool? ?? def.autoColor,
      overTimeColor: json['overTimeColor'] as int? ?? def.overTimeColor,
    );
  }

  static int _clamp(dynamic value, int min, int max, int fallback) {
    final v = value is num ? value.toInt() : fallback;
    return v.clamp(min, max);
  }

  /// Serializes for SharedPreferences / export files.
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'row': row,
        'col': col,
        'rowSpan': rowSpan,
        'colSpan': colSpan,
        if (label != null) 'label': label,
        'labelFontSize': labelFontSize,
        'labelColor': labelColor,
        'valueFontSize': valueFontSize,
        'valueColor': valueColor,
        'autoColor': autoColor,
        'overTimeColor': overTimeColor,
      };

  /// Copy with selected fields replaced. [clearLabel] resets the label to the
  /// type default (the usual `?? this` idiom cannot null a field).
  RunWidgetConfig copyWith({
    RunWidgetType? type,
    int? row,
    int? col,
    int? rowSpan,
    int? colSpan,
    String? label,
    bool clearLabel = false,
    double? labelFontSize,
    int? labelColor,
    double? valueFontSize,
    int? valueColor,
    bool? autoColor,
    int? overTimeColor,
  }) {
    return RunWidgetConfig(
      type: type ?? this.type,
      row: row ?? this.row,
      col: col ?? this.col,
      rowSpan: rowSpan ?? this.rowSpan,
      colSpan: colSpan ?? this.colSpan,
      label: clearLabel ? null : (label ?? this.label),
      labelFontSize: labelFontSize ?? this.labelFontSize,
      labelColor: labelColor ?? this.labelColor,
      valueFontSize: valueFontSize ?? this.valueFontSize,
      valueColor: valueColor ?? this.valueColor,
      autoColor: autoColor ?? this.autoColor,
      overTimeColor: overTimeColor ?? this.overTimeColor,
    );
  }
}

/// One swipeable run screen: an ordered list of tiles (order = paint order).
/// Screens have no name — they are shown as "Screen N" by position.
class RunScreenConfig {
  /// Tiles on this screen.
  final List<RunWidgetConfig> widgets;

  const RunScreenConfig({this.widgets = const []});

  /// Parses a screen, silently dropping widget entries of unknown type.
  factory RunScreenConfig.fromJson(Map<String, dynamic> json) {
    final list = json['widgets'];
    return RunScreenConfig(
      widgets: [
        if (list is List)
          for (final entry in list)
            if (entry is Map<String, dynamic>)
              if (RunWidgetConfig.tryFromJson(entry) case final config?)
                config,
      ],
    );
  }

  /// Serializes for SharedPreferences / export files.
  Map<String, dynamic> toJson() =>
      {'widgets': widgets.map((w) => w.toJson()).toList()};

  /// Copy with the widget list replaced.
  RunScreenConfig copyWith({List<RunWidgetConfig>? widgets}) =>
      RunScreenConfig(widgets: widgets ?? this.widgets);
}

/// All configured run screens plus the fixed grid dimensions.
class RunScreenLayouts {
  /// Logical grid height of every screen.
  static const int gridRows = 6;

  /// Logical grid width of every screen.
  static const int gridCols = 2;

  /// The swipeable screens, in page order.
  final List<RunScreenConfig> screens;

  const RunScreenLayouts({this.screens = const []});

  /// One screen replicating the legacy fixed run layout, so existing users
  /// see no change until they customize.
  factory RunScreenLayouts.defaults() {
    return const RunScreenLayouts(
      screens: [
        RunScreenConfig(
          widgets: [
            RunWidgetConfig(type: RunWidgetType.segmentDistance),
            RunWidgetConfig(type: RunWidgetType.abortButton, col: 1),
            RunWidgetConfig(
              type: RunWidgetType.elapsedTime,
              row: 1,
              valueFontSize: 24,
            ),
            RunWidgetConfig(
              type: RunWidgetType.nextTargetTime,
              row: 1,
              col: 1,
              valueFontSize: 24,
            ),
            RunWidgetConfig(
              type: RunWidgetType.timeLeft,
              row: 2,
              rowSpan: 2,
              colSpan: 2,
              valueFontSize: 42,
            ),
            RunWidgetConfig(
              type: RunWidgetType.finishTime,
              row: 4,
              colSpan: 2,
            ),
            RunWidgetConfig(type: RunWidgetType.previousKmButton, row: 5),
            RunWidgetConfig(type: RunWidgetType.gotItButton, row: 5, col: 1),
          ],
        ),
      ],
    );
  }

  /// Parses layouts; an empty or missing screens list stays empty so the
  /// caller (StorageService) can substitute [defaults].
  factory RunScreenLayouts.fromJson(Map<String, dynamic> json) {
    final list = json['screens'];
    return RunScreenLayouts(
      screens: [
        if (list is List)
          for (final entry in list)
            if (entry is Map<String, dynamic>) RunScreenConfig.fromJson(entry),
      ],
    );
  }

  /// Serializes for SharedPreferences / export files.
  Map<String, dynamic> toJson() =>
      {'screens': screens.map((s) => s.toJson()).toList()};

  /// Copy with the screen list replaced.
  RunScreenLayouts copyWith({List<RunScreenConfig>? screens}) =>
      RunScreenLayouts(screens: screens ?? this.screens);
}
