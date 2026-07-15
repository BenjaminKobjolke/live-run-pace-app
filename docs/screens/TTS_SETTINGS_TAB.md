# TTS Settings Tab

First tab of the full-screen [Settings screen](../SETTINGS.md) (`TTS | Gestures | MP3`).
Configures the voice announcements: on/off, speech rate/volume, audio-focus behavior,
AIMP resumption, and the post-audio tail-drain delay — plus a Test Voice preview.

Files:

| File | Role |
|------|------|
| `lib/widgets/tts_settings_tab.dart` | `TtsSettingsTab` — tab body. Stateless; values in, `ValueChanged` callbacks out. |
| `lib/screens/settings_screen.dart` | Hosts the tab; owns the edited state and the `_testTts` Test Voice logic. |
| `lib/widgets/setting_controls.dart` | `SettingSwitch` / `SettingSlider` — the reusable labeled rows used here. |

## Contract

- **In:** current values (`enabled`, `speed`, `volume`, `pauseOtherAudio`,
  `resumeAimpAfterPlayback`, `delayAfterAudioMs`), `testing` (true while the Test Voice
  preview is speaking), one `ValueChanged` callback per value, `onTestVoice`.
- **Out:** nothing directly. Edits accumulate in `SettingsScreen` state; the AppBar
  **Save** pops the whole `TtsSettings` back to `StartScreen`, which persists it.
  Back arrow discards everything.

## Layout (top → bottom)

1. **TTS Enabled** switch — master toggle. When off, every control below (and the
   whole MP3 tab) is disabled.
2. **Speed** slider (0.1–1.0, 9 divisions) — TTS speech rate.
3. **Volume** slider (0.5–2.0, 15 divisions) — TTS volume.
4. **Delay after audio** slider (0–3000 ms, 100 ms steps) — tail-drain wait after each
   post-TTS MP3 (see [SETTINGS.md → Post-TTS MP3 playback](../SETTINGS.md#post-tts-mp3-playback)).
5. **Pause other apps audio** switch — grab audio focus during announcements.
6. **Resume AIMP after playback** switch — only editable while "Pause other apps
   audio" is on (resuming only makes sense if we paused it).
7. **Test Voice** button — speaks "Pace on target. Keep it up." at the *current,
   unsaved* Speed/Volume values; label shows "Speaking..." and the button is disabled
   while it runs. Uses a throwaway isolated `TtsSpeaker` (no focus grab, no MP3, no
   AIMP resume) — see [SETTINGS.md → Test Voice](../SETTINGS.md#test-voice).

## Behavior

- Sliders/switches only edit `SettingsScreen` state — nothing takes effect until
  **Save**. Field semantics, defaults, and persistence are documented in the
  [SETTINGS.md settings table](../SETTINGS.md#settings).
- At runtime the saved values drive `TtsSpeaker` (`lib/services/tts_speaker.dart`):
  km-completion, session start/complete, and pause/resume announcements. When
  `enabled` is off, `TtsSpeaker.speak` skips the speech (announcement calls become
  no-ops).
