import 'package:flutter/material.dart';

/// Blinking text cursor shown after the value currently being edited on the
/// keypad screens. A 2px green bar fading in/out twice a second.
class BlinkingCursor extends StatefulWidget {
  /// Bar height; match the font size of the adjacent text.
  final double height;

  const BlinkingCursor({super.key, this.height = 24});

  @override
  State<BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(width: 2, height: widget.height, color: Colors.green),
    );
  }
}
