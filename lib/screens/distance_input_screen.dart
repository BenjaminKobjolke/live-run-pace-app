import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../utils/distance_format.dart';
import '../widgets/input_actions.dart';
import '../widgets/menu_button.dart';
import '../widgets/value_display.dart';
import 'distance_keypad_screen.dart';
import 'option_picker_screen.dart';

/// Compact distance editor for the small target screen. Shows the current
/// value, a unit button and a previous-distances button; tapping the value
/// opens [DistanceKeypadScreen] for editing. Pops the entered distance in
/// **kilometres** (`double`), or `null` on cancel.
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
    _value = formatDistance(widget.currentDistance);
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    List<double> suggestions = [];
    try {
      suggestions = await StorageService.instance.getDistanceSuggestions(
        limit: 6,
      );
    } catch (e) {
      // keep empty suggestions on failure
    }
    if (!mounted) return;
    setState(() {
      _suggestions = suggestions;
      _isLoading = false;
    });
  }

  /// The entered value converted to kilometres.
  double get _enteredValue {
    final value = double.tryParse(_value) ?? 0.0;
    if (_unit == 'km') return value;
    if (_unit == 'm') return value / 1000;
    return value / 0.621371; // miles to km
  }

  Future<void> _editValue() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) =>
            DistanceKeypadScreen(initialValue: _value, unit: _unit),
      ),
    );
    if (result != null) setState(() => _value = result);
  }

  Future<void> _pickUnit() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => OptionPickerScreen<String>(
          title: 'Unit',
          options: [
            for (final unit in const ['m', 'km', 'mi'])
              PickerOption(label: unit, value: unit),
          ],
        ),
      ),
    );
    if (result != null) _selectUnit(result);
  }

  Future<void> _pickPreviousDistance() async {
    final result = await Navigator.of(context).push<double>(
      MaterialPageRoute(
        builder: (_) => OptionPickerScreen<double>(
          title: 'Previous Distances',
          options: [
            for (final distance in _suggestions)
              PickerOption(
                label: '${formatDistance(distance)} km',
                value: distance,
              ),
          ],
        ),
      ),
    );
    if (result != null) _selectSuggestion(result);
  }

  void _selectSuggestion(double distance) {
    setState(() {
      _unit = 'km';
      _value = formatDistance(distance);
    });
  }

  /// Switches the active unit, converting the current value to match.
  void _selectUnit(String unit) {
    final currentKm = _enteredValue;
    final String converted;
    if (unit == 'km') {
      converted = formatDistance(currentKm);
    } else if (unit == 'm') {
      converted = (currentKm * 1000).toStringAsFixed(0);
    } else {
      converted = (currentKm * 0.621371).toStringAsFixed(2);
    }
    setState(() {
      _unit = unit;
      _value = converted;
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
              ValueDisplay(
                text: '${_value.isEmpty ? '0' : _value} $_unit',
                onTap: _editValue,
              ),
              const SizedBox(height: 12),
              MenuButton(label: 'Unit: $_unit', onTap: _pickUnit),
              if (!_isLoading && _suggestions.isNotEmpty) ...[
                const SizedBox(height: 12),
                MenuButton(
                  label: 'Previous Distances',
                  onTap: _pickPreviousDistance,
                ),
              ],
              const Spacer(),
              InputActions(
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
