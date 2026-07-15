import 'package:flutter/material.dart';
import '../widgets/menu_button.dart';

/// One selectable entry of an [OptionPickerScreen].
class PickerOption<T> {
  /// Text shown on the option row.
  final String label;

  /// Value popped when the row is tapped.
  final T value;

  const PickerOption({required this.label, required this.value});
}

/// Generic full-screen list picker: a title and big tappable rows. Tapping a
/// row pops its [PickerOption.value]; Cancel / back pops `null`.
class OptionPickerScreen<T> extends StatelessWidget {
  /// Heading, e.g. `'Unit'` or `'Previous Distances'`.
  final String title;

  /// The selectable options.
  final List<PickerOption<T>> options;

  const OptionPickerScreen({
    super.key,
    required this.title,
    required this.options,
  });

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
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: options.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final option = options[index];
                    return MenuButton(
                      label: option.label,
                      onTap: () => Navigator.of(context).pop(option.value),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
