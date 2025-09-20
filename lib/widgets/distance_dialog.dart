import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DistanceDialog extends StatefulWidget {
  final double currentDistance;

  const DistanceDialog({
    super.key,
    required this.currentDistance,
  });

  @override
  State<DistanceDialog> createState() => _DistanceDialogState();
}

class _DistanceDialogState extends State<DistanceDialog> {
  late TextEditingController _controller;
  String _unit = 'km';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentDistance.toStringAsFixed(3));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _enteredValue {
    final value = double.tryParse(_controller.text) ?? 0.0;

    if (_unit == 'km') return value;
    if (_unit == 'm') return value / 1000;
    return value / 0.621371; // miles to km
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2A2A2A),
      contentPadding: const EdgeInsets.all(20),
      content: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Distance',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            // Unit selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildUnitButton('m'),
                _buildUnitButton('km'),
                _buildUnitButton('mi'),
              ],
            ),

            const SizedBox(height: 20),

            // Text input
            TextField(
              controller: _controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.green),
                ),
                suffixText: _unit,
                suffixStyle: const TextStyle(color: Colors.white70),
              ),
              autofocus: true,
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.white70),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_enteredValue),
          child: const Text(
            'OK',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildUnitButton(String unit) {
    final isSelected = _unit == unit;
    return GestureDetector(
      onTap: () {
        setState(() {
          _unit = unit;
          // Convert current value to new unit
          final currentKm = _enteredValue;
          String newValue;
          if (unit == 'km') {
            newValue = currentKm.toStringAsFixed(3);
          } else if (unit == 'm') {
            newValue = (currentKm * 1000).toStringAsFixed(0);
          } else {
            newValue = (currentKm * 0.621371).toStringAsFixed(2);
          }
          _controller.text = newValue;
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