import 'package:flutter/material.dart';
import '../models/run_screen_layout.dart';
import '../screens/screen_editor_screen.dart';
import '../services/storage_service.dart';
import 'confirm_dialog.dart';

/// Settings tab listing the configurable run screens. Screens can be added,
/// reordered, deleted, and opened for widget editing. Every mutation persists
/// immediately via [StorageService] (independent of the TTS Save button).
class ScreensSettingsTab extends StatefulWidget {
  const ScreensSettingsTab({super.key});

  @override
  State<ScreensSettingsTab> createState() => _ScreensSettingsTabState();
}

class _ScreensSettingsTabState extends State<ScreensSettingsTab> {
  RunScreenLayouts? _layouts;

  @override
  void initState() {
    super.initState();
    StorageService.instance.loadScreenLayouts().then((layouts) {
      if (mounted) setState(() => _layouts = layouts);
    });
  }

  Future<void> _persist(RunScreenLayouts layouts) async {
    setState(() => _layouts = layouts);
    await StorageService.instance.saveScreenLayouts(layouts);
  }

  void _updateScreen(int index, RunScreenConfig screen) {
    final screens = [..._layouts!.screens];
    screens[index] = screen;
    _persist(_layouts!.copyWith(screens: screens));
  }

  void _move(int index, int delta) {
    final screens = [..._layouts!.screens];
    final target = index + delta;
    if (target < 0 || target >= screens.length) return;
    final screen = screens.removeAt(index);
    screens.insert(target, screen);
    _persist(_layouts!.copyWith(screens: screens));
  }

  Future<void> _delete(int index) async {
    if (_layouts!.screens.length <= 1) return;
    final ok = await showConfirmDialog(
      context,
      title: 'Delete Screen?',
      message: 'Delete screen ${index + 1} and its widgets?',
      confirmLabel: 'Delete',
      confirmColor: Colors.red,
    );
    if (!ok) return;
    _persist(
      _layouts!.copyWith(screens: [..._layouts!.screens]..removeAt(index)),
    );
  }

  Future<void> _reset() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Reset Screens?',
      message: 'Replace all screens with the default layout?',
      confirmLabel: 'Reset',
      confirmColor: Colors.red,
    );
    if (ok) await _persist(RunScreenLayouts.defaults());
  }

  void _open(int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ScreenEditorScreen(
          screenNumber: index + 1,
          screen: _layouts!.screens[index],
          onChanged: (screen) => _updateScreen(index, screen),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final layouts = _layouts;
    if (layouts == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: layouts.screens.length,
            itemBuilder: (context, index) {
              final screen = layouts.screens[index];
              return ListTile(
                dense: true,
                onTap: () => _open(index),
                title: Text(
                  'Screen ${index + 1}',
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  '${screen.widgets.length} widgets',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _smallIcon(Icons.arrow_upward, () => _move(index, -1)),
                    _smallIcon(Icons.arrow_downward, () => _move(index, 1)),
                    _smallIcon(Icons.delete_outline, () => _delete(index)),
                  ],
                ),
              );
            },
          ),
        ),
        TextButton.icon(
          onPressed: () => _persist(
            layouts.copyWith(screens: [...layouts.screens, const RunScreenConfig()]),
          ),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Add screen',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
        TextButton(
          onPressed: _reset,
          child: const Text(
            'Reset to defaults',
            style: TextStyle(color: Colors.white54),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _smallIcon(IconData icon, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon, color: Colors.white54, size: 18),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      onPressed: onPressed,
    );
  }
}
