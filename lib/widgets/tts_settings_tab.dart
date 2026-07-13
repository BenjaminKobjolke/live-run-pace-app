import 'package:flutter/material.dart';
import 'setting_controls.dart';

/// TTS settings tab for voice, audio focus, and playback timing controls.
class TtsSettingsTab extends StatelessWidget {
  /// Whether TTS announcements are enabled.
  final bool enabled;

  /// Current TTS speed.
  final double speed;

  /// Current TTS volume.
  final double volume;

  /// Whether other audio should be paused during playback.
  final bool pauseOtherAudio;

  /// Whether AIMP should resume after playback.
  final bool resumeAimpAfterPlayback;

  /// Delay after audio playback in milliseconds.
  final int delayAfterAudioMs;

  /// Whether the test voice preview is currently speaking.
  final bool testing;

  /// Updates [enabled].
  final ValueChanged<bool> onEnabledChanged;

  /// Updates [speed].
  final ValueChanged<double> onSpeedChanged;

  /// Updates [volume].
  final ValueChanged<double> onVolumeChanged;

  /// Updates [pauseOtherAudio].
  final ValueChanged<bool> onPauseOtherAudioChanged;

  /// Updates [resumeAimpAfterPlayback].
  final ValueChanged<bool> onResumeAimpAfterPlaybackChanged;

  /// Updates [delayAfterAudioMs].
  final ValueChanged<int> onDelayAfterAudioChanged;

  /// Starts the test voice preview.
  final VoidCallback onTestVoice;

  /// Creates a TTS settings tab.
  const TtsSettingsTab({
    super.key,
    required this.enabled,
    required this.speed,
    required this.volume,
    required this.pauseOtherAudio,
    required this.resumeAimpAfterPlayback,
    required this.delayAfterAudioMs,
    required this.testing,
    required this.onEnabledChanged,
    required this.onSpeedChanged,
    required this.onVolumeChanged,
    required this.onPauseOtherAudioChanged,
    required this.onResumeAimpAfterPlaybackChanged,
    required this.onDelayAfterAudioChanged,
    required this.onTestVoice,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingSwitch(
            label: 'TTS Enabled',
            value: enabled,
            onChanged: onEnabledChanged,
          ),
          const SizedBox(height: 20),
          SettingSlider(
            label: 'Speed: ${speed.toStringAsFixed(1)}',
            value: speed,
            min: 0.1,
            max: 1.0,
            divisions: 9,
            onChanged: enabled ? onSpeedChanged : null,
          ),
          const SizedBox(height: 20),
          SettingSlider(
            label: 'Volume: ${volume.toStringAsFixed(1)}',
            value: volume,
            min: 0.5,
            max: 2.0,
            divisions: 15,
            onChanged: enabled ? onVolumeChanged : null,
          ),
          const SizedBox(height: 20),
          SettingSlider(
            label: 'Delay after audio: $delayAfterAudioMs ms',
            value: delayAfterAudioMs.toDouble(),
            min: 0,
            max: 3000,
            divisions: 30,
            onChanged: enabled
                ? (value) => onDelayAfterAudioChanged(value.round())
                : null,
          ),
          const SizedBox(height: 20),
          SettingSwitch(
            label: 'Pause other apps audio',
            value: pauseOtherAudio,
            onChanged: enabled ? onPauseOtherAudioChanged : null,
          ),
          const SizedBox(height: 20),
          SettingSwitch(
            label: 'Resume AIMP after playback',
            value: resumeAimpAfterPlayback,
            onChanged: pauseOtherAudio
                ? onResumeAimpAfterPlaybackChanged
                : null,
          ),
          const SizedBox(height: 20),
          _outlinedButton(
            testing ? 'Speaking...' : 'Test Voice',
            enabled && !testing ? onTestVoice : null,
          ),
        ],
      ),
    );
  }

  Widget _outlinedButton(String label, VoidCallback? onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white38,
        side: const BorderSide(color: Colors.white, width: 1),
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
      child: Text(label),
    );
  }
}
