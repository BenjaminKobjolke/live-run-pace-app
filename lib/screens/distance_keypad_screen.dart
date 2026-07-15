import 'package:flutter/material.dart';
import '../widgets/digit_keypad.dart';
import '../widgets/input_actions.dart';
import '../widgets/value_display.dart';

/// Full-screen keypad editor for a distance value. Opened from
/// `DistanceInputScreen` when the value box is tapped. Pops the edited raw
/// text (`String`, in the given [unit]) on OK, or `null` on cancel.
class DistanceKeypadScreen extends StatefulWidget {
  /// The raw text to start editing.
  final String initialValue;

  /// Display-only unit suffix, e.g. `'km'`.
  final String unit;

  const DistanceKeypadScreen({
    super.key,
    required this.initialValue,
    required this.unit,
  });

  @override
  State<DistanceKeypadScreen> createState() => _DistanceKeypadScreenState();
}

class _DistanceKeypadScreenState extends State<DistanceKeypadScreen> {
  String _value = '';

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  void _onDigit(String digit) => setState(() => _value += digit);

  void _onDecimal() {
    if (_value.contains('.')) return;
    setState(() => _value = _value.isEmpty ? '0.' : '$_value.');
  }

  void _onBackspace() {
    if (_value.isEmpty) return;
    setState(() => _value = _value.substring(0, _value.length - 1));
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
              ValueDisplay(
                text: _value.isEmpty ? '0' : _value,
                suffix: widget.unit,
                showCursor: true,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: DigitKeypad(
                  allowDecimal: true,
                  onDigit: _onDigit,
                  onDecimal: _onDecimal,
                  onBackspace: _onBackspace,
                ),
              ),
              const SizedBox(height: 8),
              InputActions(
                onCancel: () => Navigator.of(context).pop(),
                onOk: () => Navigator.of(context).pop(_value),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
