import 'package:flutter/material.dart';
import '../widgets/picker_bottom_bar.dart';

/// Fullscreen integer picker for small devices: the current value huge in
/// the center, changed by sliding up/down anywhere (up = increase) or by the
/// − / + buttons for single steps. OK pops the picked int; Cancel / back
/// pops null.
class NumberPickerScreen extends StatefulWidget {
  /// Heading, e.g. 'Value size'.
  final String title;

  /// Starting value.
  final int value;

  /// Inclusive lower bound.
  final int min;

  /// Inclusive upper bound.
  final int max;

  const NumberPickerScreen({
    super.key,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
  });

  @override
  State<NumberPickerScreen> createState() => _NumberPickerScreenState();
}

class _NumberPickerScreenState extends State<NumberPickerScreen> {
  /// Drag distance for one step; tuned for a 432 px-tall screen.
  static const double _pixelsPerStep = 12;

  late int _value = widget.value.clamp(widget.min, widget.max);

  /// Accumulated drag distance not yet converted into whole steps.
  double _dragRemainder = 0;

  void _set(int value) =>
      setState(() => _value = value.clamp(widget.min, widget.max));

  void _onDragUpdate(DragUpdateDetails details) {
    _dragRemainder -= details.delta.dy; // up (negative dy) increases
    final steps = _dragRemainder ~/ _pixelsPerStep;
    if (steps != 0) {
      _dragRemainder -= steps * _pixelsPerStep;
      _set(_value + steps);
    }
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
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragUpdate: _onDragUpdate,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove,
                            color: Colors.white70, size: 32),
                        onPressed: () => _set(_value - 1),
                      ),
                      Expanded(
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '$_value',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 120,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add,
                            color: Colors.white70, size: 32),
                        onPressed: () => _set(_value + 1),
                      ),
                    ],
                  ),
                ),
              ),
              Text(
                'Slide up/down — ${widget.min} to ${widget.max}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
              const SizedBox(height: 8),
              PickerBottomBar(onOk: () => Navigator.of(context).pop(_value)),
            ],
          ),
        ),
      ),
    );
  }
}
