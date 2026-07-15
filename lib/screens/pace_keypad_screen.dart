import 'package:flutter/material.dart';
import '../widgets/digit_keypad.dart';
import '../widgets/input_actions.dart';
import '../widgets/pace_fields_row.dart';

/// Full-screen keypad editor for a pace (minutes : seconds). Opened from
/// `PaceInputScreen` when a field box is tapped. Tap a field to make it
/// active; the keypad types into the active field (max two digits) and a
/// blinking cursor marks it. Pops the entered [Duration] on OK, or `null` on
/// cancel.
class PaceKeypadScreen extends StatefulWidget {
  /// The pace to start editing.
  final Duration initialPace;

  /// Display-only unit suffix, e.g. `'km'`.
  final String unit;

  /// Field active when the screen opens: 0 = minutes, 1 = seconds.
  final int initialField;

  const PaceKeypadScreen({
    super.key,
    required this.initialPace,
    required this.unit,
    this.initialField = 0,
  });

  @override
  State<PaceKeypadScreen> createState() => _PaceKeypadScreenState();
}

class _PaceKeypadScreenState extends State<PaceKeypadScreen> {
  String _minutes = '';
  String _seconds = '';

  /// 0 = minutes field active, 1 = seconds field active.
  int _activeField = 0;

  @override
  void initState() {
    super.initState();
    _minutes = widget.initialPace.inMinutes.toString();
    _seconds = (widget.initialPace.inSeconds % 60).toString().padLeft(2, '0');
    _activeField = widget.initialField;
  }

  Duration get _pace {
    final minutes = int.tryParse(_minutes) ?? 0;
    final seconds = int.tryParse(_seconds) ?? 0;
    return Duration(minutes: minutes, seconds: seconds);
  }

  String get _activeFieldValue => _activeField == 0 ? _minutes : _seconds;

  /// Writes [value] into whichever field is active.
  void _setActiveField(String value) {
    if (_activeField == 0) {
      _minutes = value;
    } else {
      _seconds = value;
    }
  }

  void _onDigit(String digit) =>
      setState(() => _setActiveField(_appendDigit(_activeFieldValue, digit)));

  /// Appends [digit] to [field], keeping at most two digits. Replaces a lone
  /// leading `0` so typing overwrites the placeholder rather than growing it.
  String _appendDigit(String field, String digit) {
    final base = (field == '0') ? '' : field;
    if (base.length >= 2) return base;
    return base + digit;
  }

  void _onBackspace() =>
      setState(() => _setActiveField(_trim(_activeFieldValue)));

  String _trim(String field) =>
      field.isEmpty ? field : field.substring(0, field.length - 1);

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
              PaceFieldsRow(
                minutes: _minutes,
                seconds: _seconds,
                unit: widget.unit,
                activeField: _activeField,
                showCursor: true,
                onFieldTap: (index) => setState(() => _activeField = index),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: DigitKeypad(
                  allowDecimal: false,
                  onDigit: _onDigit,
                  onDecimal: () {},
                  onBackspace: _onBackspace,
                ),
              ),
              const SizedBox(height: 8),
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
