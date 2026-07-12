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

  const DistanceInputScreen({
    super.key,
    required this.currentDistance,
  });

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
      final suggestions =
          await StorageService.instance.getDistanceSuggestions(limit: 6);
      setState(() {
        _suggestions = suggestions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// The entered value converted to kilometres.
  double get _enteredValue {
    final value = double.tryParse(_value) ?? 0.0;

    if (_unit == 'km') return value;
    if (_unit == 'm') return value / 1000;
    return value / 0.621371; // miles to km
  }

  void _onDigit(String digit) {
    setState(() => _value += digit);
  }

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

              // Value display
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Text(
                  '${_value.isEmpty ? '0' : _value} $_unit',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Unit selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildUnitButton('m'),
                  _buildUnitButton('km'),
                  _buildUnitButton('mi'),
                ],
              ),

              // Suggestions
              if (!_isLoading && _suggestions.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: _suggestions.map((distance) {
                    return GestureDetector(
                      onTap: () => _selectSuggestion(distance),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Text(
                          '${distance.toStringAsFixed(3)} km',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 12),

              // Keypad fills remaining space
              Expanded(
                child: DigitKeypad(
                  allowDecimal: true,
                  onDigit: _onDigit,
                  onDecimal: _onDecimal,
                  onBackspace: _onBackspace,
                ),
              ),

              const SizedBox(height: 8),

              // Actions
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
                      onPressed: () =>
                          Navigator.of(context).pop(_enteredValue),
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

  /// Builds a unit toggle; converts the current [_value] to the new unit.
  Widget _buildUnitButton(String unit) {
    final isSelected = _unit == unit;
    return GestureDetector(
      onTap: () {
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
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : Colors.white10,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.white24,
          ),
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
