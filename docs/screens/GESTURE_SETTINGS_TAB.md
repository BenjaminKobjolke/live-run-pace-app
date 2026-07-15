# Gesture Settings Tab

Second tab of the full-screen [Settings screen](../SETTINGS.md) (`TTS | Gestures | MP3`).
Assigns an action to each of the three main-screen run gestures, and toggles the
button-navigation debounce.

Files:

| File | Role |
|------|------|
| `lib/widgets/gesture_settings_tab.dart` | `GestureSettingsTab` — tab body. Stateless; values in, `ValueChanged` callbacks out. |
| `lib/models/gesture_action.dart` | `GestureAction` — enum of assignable actions (with display `label`). |
| `lib/screens/settings_screen.dart` | Hosts the tab; owns the edited state. |
| `lib/widgets/setting_controls.dart` | `SettingDropdown<T>` / `SettingSwitch` — the reusable labeled rows used here. |

## Contract

- **In:** current values (`singleTapAction`, `doubleTapAction`, `longPressAction`,
  `buttonNavigationDelay`), one `ValueChanged` callback per value.
- **Out:** nothing directly. Edits accumulate in `SettingsScreen` state; the AppBar
  **Save** pops the whole `TtsSettings` back to `StartScreen`, which persists it.
  Back arrow discards everything.

## Layout (top → bottom)

1. **Single tap** dropdown — `GestureAction` (default `none`).
2. **Double tap** dropdown — `GestureAction` (default `none`).
3. **Long press** dropdown — `GestureAction` (default `pause`).
4. **Delay button navigation** switch — ~1s debounce after each km change to prevent
   accidental double-advances (default on).

## Behavior

Each dropdown offers all `GestureAction` values: `none`, `toggleAimp`, `completeKm`,
`previousKm`, `pause`, `abort`. What each action does on the run screen — handler
resolution, debounce gating, `none` disabling the gesture — is documented in
[SESSIONS.md → Gestures](../SESSIONS.md#gestures-main-screen) and
[SETTINGS.md → Gesture actions](../SETTINGS.md#gesture-actions); this tab only picks
the assignment.

**Migration:** the former `touchToToggleAimp` / `doubleTapToCompleteKm` booleans
migrate into these fields on load — see
[SETTINGS.md → Gesture actions](../SETTINGS.md#gesture-actions).
