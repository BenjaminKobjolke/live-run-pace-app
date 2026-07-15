import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/run_widget_style.dart';
import '../utils/color_hex.dart';
import '../widgets/picker_bottom_bar.dart';
import '../widgets/setting_controls.dart';

/// Full-screen color picker (fits 240x432): preset swatches, ARGB sliders,
/// live preview, and clipboard Copy/Paste so colors can be reused across
/// widgets. OK pops the picked [Color]; Cancel / back pops null.
class ColorPickerScreen extends StatefulWidget {
  /// Heading, e.g. 'Value color'.
  final String title;

  /// The color the picker starts at.
  final Color initialColor;

  const ColorPickerScreen({
    super.key,
    required this.title,
    required this.initialColor,
  });

  @override
  State<ColorPickerScreen> createState() => _ColorPickerScreenState();
}

class _ColorPickerScreenState extends State<ColorPickerScreen> {
  late Color _color = widget.initialColor;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: colorToHex(_color)));
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final pasted = data?.text == null ? null : tryParseHexColor(data!.text!);
    if (!mounted) return;
    if (pasted == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clipboard has no color (#AARRGGBB)')),
      );
      return;
    }
    setState(() => _color = pasted);
  }

  /// One ARGB channel slider; [shift] is the channel's bit offset.
  Widget _channelSlider(String name, int shift) {
    final argb = _color.toARGB32();
    final value = (argb >> shift) & 0xFF;
    return SettingSlider(
      label: '$name: $value',
      value: value.toDouble(),
      min: 0,
      max: 255,
      divisions: 255,
      onChanged: (v) {
        final updated = (argb & ~(0xFF << shift)) | (v.round() << shift);
        setState(() => _color = Color(updated));
      },
    );
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
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: _color,
                          border: Border.all(color: Colors.white30),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          colorToHex(_color),
                          style: TextStyle(
                            color: _color.computeLuminance() > 0.4
                                ? Colors.black
                                : Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final swatch in presetSwatches)
                            InkWell(
                              onTap: () => setState(() => _color = swatch),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: swatch,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _color == swatch
                                        ? Colors.white
                                        : Colors.white30,
                                    width: _color == swatch ? 2 : 1,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _channelSlider('Alpha', 24),
                      _channelSlider('Red', 16),
                      _channelSlider('Green', 8),
                      _channelSlider('Blue', 0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                            onPressed: _copy,
                            child: const Text(
                              'Copy',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                          TextButton(
                            onPressed: _paste,
                            child: const Text(
                              'Paste',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              PickerBottomBar(onOk: () => Navigator.of(context).pop(_color)),
            ],
          ),
        ),
      ),
    );
  }
}
