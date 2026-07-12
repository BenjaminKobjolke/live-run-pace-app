import 'package:flutter/material.dart';
import '../widgets/digit_keypad.dart';

/// Full-screen pace editor (minutes : seconds per km/mile) driven by an
/// on-screen [DigitKeypad]. Tap a field to make it active; the keypad types
/// into the active field (max two digits). Pops the entered [Duration], or
/// `null` on cancel.
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
  String _minutes = '';
  String _seconds = '';
  String _unit = 'km';

  /// 0 = minutes field active, 1 = seconds field active.
  int _activeField = 0;

  @override
  void initState() {
    super.initState();
    _minutes = widget.currentPace.inMinutes.toString();
    _seconds = (widget.currentPace.inSeconds % 60).toString().padLeft(2, '0');
  }

  Duration get _pace {
    final minutes = int.tryParse(_minutes) ?? 0;
    final seconds = int.tryParse(_seconds) ?? 0;
    return Duration(minutes: minutes, seconds: seconds);
  }

  void _onDigit(String digit) {
    setState(() {
      if (_activeField == 0) {
        _minutes = _appendDigit(_minutes, digit);
      } else {
        _seconds = _appendDigit(_seconds, digit);
      }
    });
  }

  /// Appends [digit] to [field], keeping at most two digits. Replaces a lone
  /// leading `0` so typing overwrites the placeholder rather than growing it.
  String _appendDigit(String field, String digit) {
    final base = (field == '0') ? '' : field;
    if (base.length >= 2) return base;
    return base + digit;
  }

  void _onBackspace() {
    setState(() {
      if (_activeField == 0) {
        _minutes = _trim(_minutes);
      } else {
        _seconds = _trim(_seconds);
      }
    });
  }

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

              // Minutes : Seconds fields
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(child: _buildField(_minutes, 'min', 0)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      ':',
                      style: TextStyle(color: Colors.white, fontSize: 28),
                    ),
                  ),
                  Expanded(child: _buildField(_seconds, 'sec', 1)),
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      '/ $_unit',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Unit selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildUnitButton('km'),
                  const SizedBox(width: 16),
                  _buildUnitButton('mile'),
                ],
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

              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white70, fontSize: 18),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(_pace),
                      child: const Text(
                        'OK',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// A tappable value box for a pace field; highlighted when active.
  Widget _buildField(String value, String label, int index) {
    final isActive = _activeField == index;
    return GestureDetector(
      onTap: () => setState(() => _activeField = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? Colors.green : Colors.white24,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              value.isEmpty ? '0' : value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitButton(String unit) {
    final isSelected = _unit == unit;
    return GestureDetector(
      onTap: () => setState(() => _unit = unit),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : Colors.white10,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSelected ? Colors.green : Colors.white24),
        ),
        child: Text(
          unit,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
