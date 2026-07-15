import 'package:flutter/material.dart';
import '../widgets/input_actions.dart';
import '../widgets/menu_button.dart';
import '../widgets/pace_fields_row.dart';
import 'option_picker_screen.dart';
import 'pace_keypad_screen.dart';

/// Compact pace editor (minutes : seconds per km/mile) for the small target
/// screen. Shows the current pace as two tappable MM / SS boxes and a unit
/// button; tapping a box opens [PaceKeypadScreen] with that field active.
/// Pops the entered [Duration], or `null` on cancel.
class PaceInputScreen extends StatefulWidget {
  /// Current pace, shown when the screen opens.
  final Duration currentPace;

  /// Heading, e.g. `'Target Pace'` or `'Max Pace'`.
  final String title;

  const PaceInputScreen({
    super.key,
    required this.currentPace,
    this.title = 'Pace',
  });

  @override
  State<PaceInputScreen> createState() => _PaceInputScreenState();
}

class _PaceInputScreenState extends State<PaceInputScreen> {
  Duration _pace = Duration.zero;
  String _unit = 'km';

  @override
  void initState() {
    super.initState();
    _pace = widget.currentPace;
  }

  String get _minutesText => _pace.inMinutes.toString();

  String get _secondsText =>
      (_pace.inSeconds % 60).toString().padLeft(2, '0');

  Future<void> _editValue(int field) async {
    final result = await Navigator.of(context).push<Duration>(
      MaterialPageRoute(
        builder: (_) => PaceKeypadScreen(
          initialPace: _pace,
          unit: _unit,
          initialField: field,
        ),
      ),
    );
    if (result != null) setState(() => _pace = result);
  }

  Future<void> _pickUnit() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => OptionPickerScreen<String>(
          title: 'Unit',
          options: [
            for (final unit in const ['km', 'mile'])
              PickerOption(label: unit, value: unit),
          ],
        ),
      ),
    );
    if (result != null) setState(() => _unit = result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              PaceFieldsRow(
                minutes: _minutesText,
                seconds: _secondsText,
                unit: _unit,
                onFieldTap: _editValue,
              ),
              const SizedBox(height: 12),
              MenuButton(label: 'Unit: $_unit', onTap: _pickUnit),
              const Spacer(),
              InputActions(
                onCancel: () => Navigator.of(context).pop(),
                onOk: () => Navigator.of(context).pop(_pace),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
