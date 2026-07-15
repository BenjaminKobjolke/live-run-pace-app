import 'package:flutter/material.dart';
import '../screens/color_picker_screen.dart';

/// A labeled on/off switch row used throughout the settings screen.
class SettingSwitch extends StatelessWidget {
  final String label;
  final bool value;

  /// Null disables the switch.
  final ValueChanged<bool>? onChanged;

  const SettingSwitch({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.white,
        ),
      ],
    );
  }
}

/// A labeled dropdown row for choosing one value of type [T], styled to match
/// the other setting controls (white-on-black).
class SettingDropdown<T> extends StatelessWidget {
  final String label;
  final T value;

  /// Selectable values shown in the dropdown.
  final List<T> items;

  /// Maps a value to its display text.
  final String Function(T) itemLabel;

  /// Null disables the dropdown.
  final ValueChanged<T?>? onChanged;

  const SettingDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
        DropdownButton<T>(
          value: value,
          onChanged: onChanged,
          dropdownColor: Colors.black,
          iconEnabledColor: Colors.white,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          underline: Container(height: 1, color: Colors.white30),
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    itemLabel(item),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

/// A labeled color row: tapping the swatch opens the full-screen
/// [ColorPickerScreen] and reports the picked color via [onChanged].
class ColorSettingRow extends StatelessWidget {
  final String label;
  final Color value;

  /// Receives the newly picked color.
  final ValueChanged<Color> onChanged;

  const ColorSettingRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  Future<void> _pick(BuildContext context) async {
    final picked = await Navigator.of(context).push<Color>(
      MaterialPageRoute(
        builder: (context) =>
            ColorPickerScreen(title: label, initialColor: value),
      ),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
        InkWell(
          onTap: () => _pick(context),
          child: Container(
            width: 32,
            height: 24,
            decoration: BoxDecoration(
              color: value,
              border: Border.all(color: Colors.white30),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    );
  }
}

/// A labeled row that navigates to a fullscreen picker: current value text
/// plus a chevron on the right; the caller's [onTap] pushes the picker and
/// applies the result. Small-screen replacement for inline dropdowns/sliders.
class SettingPickerRow extends StatelessWidget {
  final String label;

  /// Display text of the current value.
  final String value;

  /// Opens the fullscreen picker.
  final VoidCallback onTap;

  const SettingPickerRow({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            Text(
              value,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const Icon(Icons.chevron_right, color: Colors.white54, size: 20),
          ],
        ),
      ),
    );
  }
}

/// A labeled slider row. [label] should already include the current value text.
class SettingSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;

  /// Null disables the slider.
  final ValueChanged<double>? onChanged;

  const SettingSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
          activeColor: Colors.white,
          inactiveColor: Colors.white30,
        ),
      ],
    );
  }
}
