import 'package:flutter/material.dart';
import '../models/run_screen_layout.dart';
import '../utils/demo_session.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/run_screen_callbacks.dart';
import '../widgets/run_screen_grid.dart';
import '../widgets/setting_controls.dart';
import 'widget_editor_pickers.dart';

/// Edits one [RunWidgetConfig]: type, grid placement, label and colors, with
/// a live tile preview at the top that reflects every change instantly.
/// Save pops the edited config; back pops null (no change). When [onDelete]
/// is provided (editing an existing widget) a Delete button confirms, fires
/// the callback and closes the editor.
class WidgetEditorScreen extends StatefulWidget {
  /// The tile configuration to edit.
  final RunWidgetConfig config;

  /// Deletes the widget from its screen; null when adding a new widget.
  final VoidCallback? onDelete;

  const WidgetEditorScreen({super.key, required this.config, this.onDelete});

  @override
  State<WidgetEditorScreen> createState() => _WidgetEditorScreenState();
}

class _WidgetEditorScreenState extends State<WidgetEditorScreen> {
  late RunWidgetConfig _config = widget.config;
  late final TextEditingController _labelController =
      TextEditingController(text: widget.config.label ?? '');

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  void _update(RunWidgetConfig updated) {
    // Keep spans inside the grid when the position moved.
    final rowSpan = updated.rowSpan
        .clamp(1, RunScreenLayouts.gridRows - updated.row);
    final colSpan = updated.colSpan
        .clamp(1, RunScreenLayouts.gridCols - updated.col);
    setState(
      () => _config = updated.copyWith(rowSpan: rowSpan, colSpan: colSpan),
    );
  }

  void _save() {
    final label = _labelController.text.trim();
    Navigator.of(context).pop(
      label.isEmpty
          ? _config.copyWith(clearLabel: true)
          : _config.copyWith(label: label),
    );
  }

  /// Pushes the option picker (widget_editor_pickers.dart), applies non-null.
  Future<void> _pickNumberOption(
    String title,
    int min,
    int max,
    String Function(int) display,
    void Function(int) apply,
  ) async {
    final picked = await pickNumberOption(context, title, min, max, display);
    if (picked != null) apply(picked);
  }

  /// Pushes the number picker (widget_editor_pickers.dart), applies non-null.
  Future<void> _pickSize(
    String title,
    double value,
    int min,
    int max,
    void Function(double) apply,
  ) async {
    final picked = await pickSize(context, title, value, min, max);
    if (picked != null) apply(picked.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final isControl = _config.type.isControl;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Widget'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _preview(),
            const SizedBox(height: 12),
            SettingPickerRow(
              label: 'Type',
              value: _config.type.label,
              onTap: _pickType,
            ),
            SettingPickerRow(
              label: 'Row',
              value: '${_config.row + 1}',
              onTap: () => _pickNumberOption(
                  'Row', 0, RunScreenLayouts.gridRows - 1,
                  (v) => 'Row ${v + 1}',
                  (v) => _update(_config.copyWith(row: v))),
            ),
            SettingPickerRow(
              label: 'Column',
              value: '${_config.col + 1}',
              onTap: () => _pickNumberOption(
                  'Column', 0, RunScreenLayouts.gridCols - 1,
                  (v) => 'Column ${v + 1}',
                  (v) => _update(_config.copyWith(col: v))),
            ),
            SettingPickerRow(
              label: 'Rows filled',
              value: '${_config.rowSpan}',
              onTap: () => _pickNumberOption(
                  'Rows filled', 1, RunScreenLayouts.gridRows - _config.row,
                  (v) => '$v',
                  (v) => _update(_config.copyWith(rowSpan: v))),
            ),
            SettingPickerRow(
              label: 'Columns filled',
              value: '${_config.colSpan}',
              onTap: () => _pickNumberOption(
                  'Columns filled', 1,
                  RunScreenLayouts.gridCols - _config.col,
                  (v) => '$v',
                  (v) => _update(_config.copyWith(colSpan: v))),
            ),
            if (!isControl) ..._statStyleFields(),
            if (isControl)
              SettingPickerRow(
                label: 'Button size',
                value: '${_config.valueFontSize.round()}',
                onTap: () => _pickSize(
                    'Button size', _config.valueFontSize, 12, 72,
                    (v) => _update(_config.copyWith(valueFontSize: v))),
              ),
            if (widget.onDelete != null) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: _delete,
                child: const Text(
                  'Delete widget',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Live preview of the tile with demo values, sized proportionally to the
  /// configured span (height capped so tall spans don't crowd the form —
  /// FittedBox in the tiles shrinks content to fit).
  Widget _preview() {
    final height = (28.0 * _config.rowSpan).clamp(48.0, 120.0);
    return Center(
      child: FractionallySizedBox(
        widthFactor: _config.colSpan / RunScreenLayouts.gridCols,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white12),
          ),
          child: AbsorbPointer(
            child: runTileFor(
              _config,
              demoSession(),
              RunScreenCallbacks.noop(),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _delete() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Delete Widget?',
      message: 'Remove "${_config.effectiveLabel.isEmpty ? _config.type.label : _config.effectiveLabel}"?',
      confirmLabel: 'Delete',
      confirmColor: Colors.red,
    );
    if (!ok || !mounted) return;
    widget.onDelete!();
    Navigator.of(context).pop();
  }

  List<Widget> _statStyleFields() {
    return [
      const SizedBox(height: 8),
      TextField(
        controller: _labelController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: 'Label (empty = "${_config.type.defaultLabel}")',
          labelStyle: const TextStyle(color: Colors.white70),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white30),
          ),
        ),
      ),
      const SizedBox(height: 8),
      SettingPickerRow(
        label: 'Label size',
        value: '${_config.labelFontSize.round()}',
        onTap: () => _pickSize('Label size', _config.labelFontSize, 8, 24,
            (v) => _update(_config.copyWith(labelFontSize: v))),
      ),
      ColorSettingRow(
        label: 'Label color',
        value: Color(_config.labelColor),
        onChanged: (c) =>
            _update(_config.copyWith(labelColor: c.toARGB32())),
      ),
      SettingPickerRow(
        label: 'Value size',
        value: '${_config.valueFontSize.round()}',
        onTap: () => _pickSize('Value size', _config.valueFontSize, 12, 72,
            (v) => _update(_config.copyWith(valueFontSize: v))),
      ),
      ..._valueColorFields(),
    ];
  }

  Future<void> _pickType() async {
    final picked = await pickWidgetType(context);
    if (picked != null) _update(_config.copyWith(type: picked));
  }

  /// Status-colored types offer auto colors (default) or a custom
  /// on-schedule/behind pair; other types have a single value color.
  List<Widget> _valueColorFields() {
    if (!_config.type.hasStatusColor) {
      return [
        ColorSettingRow(
          label: 'Value color',
          value: Color(_config.valueColor),
          onChanged: (c) =>
              _update(_config.copyWith(valueColor: c.toARGB32())),
        ),
      ];
    }
    return [
      SettingSwitch(
        label: 'Auto colors (green/red)',
        value: _config.autoColor,
        onChanged: (v) => _update(_config.copyWith(autoColor: v)),
      ),
      if (!_config.autoColor) ...[
        ColorSettingRow(
          label: 'On schedule color',
          value: Color(_config.valueColor),
          onChanged: (c) =>
              _update(_config.copyWith(valueColor: c.toARGB32())),
        ),
        ColorSettingRow(
          label: 'Behind color',
          value: Color(_config.overTimeColor),
          onChanged: (c) =>
              _update(_config.copyWith(overTimeColor: c.toARGB32())),
        ),
      ],
    ];
  }
}
