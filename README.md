# Live Run Pace App

A Flutter app designed for runners to track their pace and kilometer targets during runs. Optimized for small screen Android devices (240x432 resolution).

## Features

### 🏃 Core Running Features
- **Pace Tracking**: Set your target pace per kilometer
- **Distance Goals**: Support for any distance (marathon, half-marathon, custom)
- **Real-time Progress**: Live countdown to next kilometer target
- **Visual Feedback**: Color-coded time display (green = on pace, red = behind)

### 📱 User Experience
- **Configurable Run Screens**: Build your own swipeable dashboard — place stat and button widgets on a grid, set sizes and colors per widget (Settings → Screens, see `docs/SCREEN_LAYOUTS.md`)
- **Settings Backup**: Export/import all settings to a JSON file (Settings → Backup, see `docs/IMPORT_EXPORT.md`)
- **Persistent Storage**: Settings and active sessions saved automatically
- **Session Recovery**: Resume interrupted runs if app closes
- **Multi-modal Feedback**: Visual flash + vibration + voice announcements
- **Small Screen Optimized**: Perfect for compact Android devices

### 🔊 Smart Audio Features
**Text-to-Speech Announcements:**
When you reach each kilometer, the app announces:
- "The next target is kilometer 5. You have 5 minutes and 20 seconds left to reach the next target."
- "You are 1 minute behind schedule" (when running late)
- "Final kilometer! You have 6 minutes left to finish."

**Custom Audio Alerts:**
- Add your own MP3/WAV/M4A files for post-announcement sounds
- Multiple file support with random selection for variety
- Individual file selection or bulk folder import
- Automatic audio focus management (pauses/resumes other apps)

**AIMP Music Player Integration:**
- Touch main screen to play/pause AIMP music player
- Automatic AIMP resume after TTS announcements
- Seamless audio switching between running music and pace updates

### ⚙️ Technical Features
- **Auto-save**: Progress saved every 10 seconds
- **Battery Optimized**: only time widgets on the visible screen update every second (1s tick event); everything else repaints only on kilometer changes
- **Offline**: No internet required during runs
- **Cross-platform**: Android and Web support

## Quick Start

### 1. Setup
```bash
# Clone and setup the project
git clone <repository-url>
cd live_run_pace_app
install.bat  # Windows users
```

### 2. Run the App
```bash
# Android device/emulator
flutter run

# Web browser
flutter run -d chrome
```

### 3. Build APK
```bash
# Use provided script
build_apk.bat

# Or manually
flutter build apk --debug
```

### 🎛️ Advanced Settings
Access detailed configuration via the settings gear icon:

**Text-to-Speech Options:**
- Enable/disable voice announcements
- Adjust speech speed (0.1x to 1.0x)
- Control TTS volume (0.5x to 2.0x)
- **Test Voice**: preview the current speed/volume before saving
- Audio focus management (pause other apps during announcements)

**Custom Audio Files:**
- **Add Files**: Select individual MP3/WAV/M4A files
- **Add Folder**: Bulk import all audio files from a directory
- **Refresh Folder**: re-scan the last-picked folder to pick up newly added files
- Random sound selection after each TTS announcement
- Scrollable file list with individual remove options

**Interaction Controls:**
- Assign an action to each gesture — single tap / double tap / long press
- Actions: None, Toggle AIMP, Complete km, Previous km, Pause, Abort
- Auto-resume AIMP after TTS announcements

**Run Screens (Settings → Screens):**
- Multiple swipeable screens during a run, each a 6×2 grid of widgets
- WYSIWYG editor: the screen is shown as it will look — tap an empty cell to add a widget, tap a widget to edit it, with a live preview while adjusting sizes and colors
- Widgets: segment distance, elapsed time, next target, time left, finish time, current/average pace, GOT IT!/back/abort buttons
- Per widget: grid position and span, label text, label/value sizes and colors
- Time left: auto green/red status colors (default) or a custom color pair
- Full-screen color picker with clipboard Copy/Paste to reuse colors

**Backup (Settings → Backup):**
- Export all settings (paces, TTS, gestures, MP3 list, run screens) to a JSON file
- Import them back — versioned, forward-tolerant format

**Android Compatibility:**
- Android 5.0+ support with version-specific optimizations
- Android 8 compatibility for file picker operations
- Proper permission handling across Android versions

## Usage

### Initial Setup
1. **Set Distance**: Tap distance field (default: 42.195 km marathon)
2. **Set Target Pace**: Tap target pace field (default: 6:00 min/km)
3. **Set Max Pace**: Tap max pace field (fallback pace when behind schedule)
4. **Configure Audio**: Tap settings gear icon to access TTS and audio options
5. **Start Run**: Press the START button

### During Your Run
1. **Monitor Progress**: Watch the color-coded time remaining
   - 🟢 Green: On pace or ahead
   - 🔴 Red: Behind schedule
2. **Mark Kilometers**:
   - Press "GOT IT!" button when you reach each km
   - OR use a gesture assigned to "Complete km" in settings
3. **Audio Control**:
   - Assign "Toggle AIMP" to a gesture to play/pause music from the main screen
   - Listen to voice announcements with optional custom sound alerts
4. **Navigate**: Use back arrow to undo accidental taps

### Session Management
- **Abort**: Tap X button (with confirmation)
- **Auto-recovery**: App resumes if accidentally closed
- **Completion**: View detailed breakdown of each kilometer

## Screenshots

See `screenshots/` folder for UI examples:
- Start screen with distance/pace settings
- Main running interface
- Settings dialogs

## Technical Requirements

### Platforms
- **Android**: Minimum SDK 21 (Android 5.0+)
- **Web**: Modern browsers with JavaScript enabled

### Device Requirements
- **Screen**: Optimized for 240x432 but works on any size
- **Permissions**:
  - Vibration (for haptic feedback)
  - Storage/Audio (for custom MP3 file selection)
- **Audio**: Text-to-speech for voice announcements
- **Optional**: AIMP music player for integrated music control

### Dependencies
- `flutter`: SDK framework
- `shared_preferences`: Settings persistence
- `vibration`: Haptic feedback
- `flutter_tts`: Voice announcements
- `file_picker`: File and folder selection
- `audioplayers`: Custom MP3 playback
- `permission_handler`: Storage permissions
- `audio_session`: Audio focus management
- `device_info_plus`: Android version detection
- `flutter_launcher_icons`: Custom app icon generation

## Development

### Project Structure
```
lib/
├── main.dart              # App entry point
├── models/                # Data models
│   ├── app_settings.dart  # Distance/pace settings
│   ├── running_session.dart # Session tracking
│   ├── run_screen_layout.dart # Configurable run screens (grid widgets)
│   └── tts_settings.dart  # Audio/TTS configuration
├── screens/               # UI screens
│   ├── start_screen.dart  # Initial setup
│   ├── main_screen.dart   # Running interface (swipeable widget screens)
│   ├── settings_screen.dart # 5-tab settings (TTS/Gestures/MP3/Screens/Backup)
│   ├── distance_input_screen.dart # Full-screen distance keypad
│   ├── pace_input_screen.dart     # Full-screen pace keypad
│   └── completion_screen.dart # Results
├── services/              # Business logic
│   ├── storage_service.dart # Data persistence
│   ├── settings_transfer_service.dart # Settings JSON export/import
│   ├── run_widget_values.dart / run_widget_style.dart # Widget value/style resolution
│   └── tts_speaker.dart   # Audio/TTS management
└── widgets/               # Reusable components
    ├── run_screen_pager.dart / run_screen_grid.dart # Run dashboard rendering
    └── digit_keypad.dart  # On-screen numeric keypad
```

### Build Scripts
- `install.bat` - Setup platforms and dependencies
- `build_apk.bat` - Build debug APK

### Git Workflow
Platform directories (`android/`, `web/`) are excluded from git and regenerated via `install.bat` following Flutter best practices.

### Debugging

#### ADB Commands for Android Debugging

**Clear logs before testing:**
```bash
adb logcat -c
```

**View Flutter logs only:**
```bash
# Windows
adb logcat | findstr flutter

# Linux/Mac
adb logcat | grep flutter

# Verbose Flutter logs only
adb logcat *:S flutter:V
```

**View app-specific logs:**
```bash
# All logs from the app
adb logcat | findstr "com.kobjolke.live_run_pace"
```

**Monitor audio and TTS events:**
```bash
# Filter for audio focus, TTS, MP3, and AIMP events
adb logcat | findstr "Audio\|TTS\|MP3\|AIMP\|flutter"

# Monitor AIMP screen tap functionality specifically
adb logcat | findstr "Screen\|toggleAimp\|AIMP"
```

**Save logs to file for analysis:**
```bash
# Capture all logs
adb logcat > debug_log.txt

# Capture Flutter logs only
adb logcat | findstr flutter > flutter_log.txt
```

**Complete debugging workflow:**
```bash
# 1. Clear old logs
adb logcat -c

# 2. Run the app and reproduce the issue

# 3. View live logs
adb logcat | findstr flutter

# 4. Or save to file for detailed analysis
adb logcat > debug_log.txt
```

**Common log patterns to watch for:**
- `Audio focus acquired/released` - Audio session management
- `TTS playback completed` - Text-to-speech events
- `MP3 playback` - Audio file playback
- `AIMP resume command` - AIMP integration
- `Audio interruption event` - Audio focus conflicts
- `Screen tap detected, calling toggleAimp` - Screen tap functionality
- `toggleAimp method called via method channel` - AIMP toggle debug
- `Sending AIMP playOrPause intent` - AIMP intent sending

## Contributing

1. Run `install.bat` to setup development environment
2. Follow existing code style and patterns
3. Test on small screen devices when possible
4. Update documentation for significant changes

## License

See LICENSE file for details.
