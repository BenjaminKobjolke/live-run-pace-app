import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../widgets/digit_keypad.dart';

/// Full-screen distance editor driven by an on-screen [DigitKeypad] instead of
/// the OS keyboard. Pops the entered distance in **kilometres** (`double`), or
/// `null` on cancel. Keeps the unit selector (m/km/mi) and the "Frequently
/// Used" suggestion chips from the previous dialog.
class DistanceInputScreen extends StatefulWidget {
  /// Current distance in kilometres, shown when the screen opens.
  final double currentDistance;

  const DistanceInputScreen({super.key, required this.currentDistance});

  @override
  State<DistanceInputScreen> createState() => _DistanceInputScreenState();
}

class _DistanceInputScreenState extends State<DistanceInputScreen> {
  /// The raw text being edited (in the currently selected [_unit]).
  String _value = '';
  String _unit = 'km';
  List<double> _suggestions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _value = widget.currentDistance.toStringAsFixed(3);
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    try {
      final suggestions = await StorageService.instance.getDistanceSuggestions(
        limit: 6,
      );
      setState(() {
        _suggestions = suggestions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  /// The entered value converted to kilometres.
  double get _enteredValue {
    final value = double.tryParse(_value) ?? 0.0;
    if (_unit == 'km') return value;
    if (_unit == 'm') return value / 1000;
    return value / 0.621371; // miles to km
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

  void _selectSuggestion(double distance) {
    setState(() {
      _unit = 'km';
      _value = distance.toStringAsFixed(3);
    });
  }

  /// Switches the active unit, converting the current value to match.
  void _selectUnit(String unit) {
    setState(() {
      final currentKm = _enteredValue;
      _unit = unit;
      if (unit == 'km') {
        _value = currentKm.toStringAsFixed(3);
      } else if (unit == 'm') {
        _value = (currentKm * 1000).toStringAsFixed(0);
      } else {
        _value = (currentKm * 0.621371).toStringAsFixed(2);
      }
    });
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
              const Text(
                'Distance',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _ValueDisplay(text: '${_value.isEmpty ? '0' : _value} $_unit'),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final unit in const ['m', 'km', 'mi'])
                    _UnitButton(
                      unit: unit,
                      isSelected: _unit == unit,
                      onTap: () => _selectUnit(unit),
                    ),
                ],
              ),
              if (!_isLoading && _suggestions.isNotEmpty) ...[
                const SizedBox(height: 12),
                _SuggestionChips(
                  suggestions: _suggestions,
                  onSelect: _selectSuggestion,
                ),
              ],
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
              _InputActions(
                onCancel: () => Navigator.of(context).pop(),
                onOk: () => Navigator.of(context).pop(_enteredValue),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The large centred read-out of the value currently being entered.
class _ValueDisplay extends StatelessWidget {
  final String text;

  const _ValueDisplay({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// A single unit toggle (m/km/mi), highlighted when [isSelected].
class _UnitButton extends StatelessWidget {
  final String unit;
  final bool isSelected;
  final VoidCallback onTap;

  const _UnitButton({
    required this.unit,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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

/// Wrap of tappable "frequently used" distance chips (values in km).
class _SuggestionChips extends StatelessWidget {
  final List<double> suggestions;
  final ValueChanged<double> onSelect;

  const _SuggestionChips({required this.suggestions, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final distance in suggestions)
          GestureDetector(
            onTap: () => onSelect(distance),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                '${distance.toStringAsFixed(3)} km',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }
}

/// Cancel / OK action row for the input screen.
class _InputActions extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onOk;

  const _InputActions({required this.onCancel, required this.onOk});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: onCancel,
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
            onPressed: onOk,
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
    );
  }
}
