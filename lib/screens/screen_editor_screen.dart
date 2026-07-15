import 'package:flutter/material.dart';
import '../models/run_screen_layout.dart';
import '../models/run_widget_type.dart';
import '../utils/demo_session.dart';
import '../widgets/editable_screen_grid.dart';
import 'widget_editor_screen.dart';

/// WYSIWYG editor for one run screen: the grid is rendered exactly like the
/// live run screen (with demo values). Tapping an empty cell adds a widget
/// there; tapping a widget opens its editor (which can also delete it).
/// Every mutation is reported via [onChanged] immediately (the Screens tab
/// persists), so plain back navigation never loses anything.
class ScreenEditorScreen extends StatefulWidget {
  /// 1-based position, only for the title ("Screen 2").
  final int screenNumber;

  /// The screen being edited.
  final RunScreenConfig screen;

  /// Called with the updated screen after every mutation.
  final ValueChanged<RunScreenConfig> onChanged;

  const ScreenEditorScreen({
    super.key,
    required this.screenNumber,
    required this.screen,
    required this.onChanged,
  });

  @override
  State<ScreenEditorScreen> createState() => _ScreenEditorScreenState();
}

class _ScreenEditorScreenState extends State<ScreenEditorScreen> {
  late RunScreenConfig _screen = widget.screen;

  void _update(List<RunWidgetConfig> widgets) {
    setState(() => _screen = _screen.copyWith(widgets: widgets));
    widget.onChanged(_screen);
  }

  Future<void> _onCellTap(int row, int col, int? widgetIndex) {
    return widgetIndex == null
        ? _addWidget(row, col)
        : _editWidget(widgetIndex);
  }

  Future<void> _addWidget(int row, int col) async {
    final added = await Navigator.of(context).push<RunWidgetConfig>(
      MaterialPageRoute(
        builder: (context) => WidgetEditorScreen(
          config: RunWidgetConfig(
            type: RunWidgetType.elapsedTime,
            row: row,
            col: col,
          ),
        ),
      ),
    );
    if (added != null) _update([..._screen.widgets, added]);
  }

  Future<void> _editWidget(int index) async {
    final edited = await Navigator.of(context).push<RunWidgetConfig>(
      MaterialPageRoute(
        builder: (context) => WidgetEditorScreen(
          config: _screen.widgets[index],
          onDelete: () => _update([..._screen.widgets]..removeAt(index)),
        ),
      ),
    );
    if (edited == null) return;
    final widgets = [..._screen.widgets];
    widgets[index] = edited;
    _update(widgets);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('Screen ${widget.screenNumber}'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'Tap a cell to add or edit a widget',
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ),
            Expanded(
              child: Padding(
                // Same padding as the live run screen, so proportions match.
                padding: const EdgeInsets.all(16),
                child: EditableScreenGrid(
                  screen: _screen,
                  session: demoSession(),
                  onCellTap: _onCellTap,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
