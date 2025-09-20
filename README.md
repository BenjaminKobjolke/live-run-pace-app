# Live Run Pace App

A Flutter app designed for runners to track their pace and kilometer targets during runs. Optimized for small screen Android devices (240x432 resolution).

## Features

### 🏃 Core Running Features
- **Pace Tracking**: Set your target pace per kilometer
- **Distance Goals**: Support for any distance (marathon, half-marathon, custom)
- **Real-time Progress**: Live countdown to next kilometer target
- **Visual Feedback**: Color-coded time display (green = on pace, red = behind)

### 📱 User Experience
- **Persistent Storage**: Settings and active sessions saved automatically
- **Session Recovery**: Resume interrupted runs if app closes
- **Multi-modal Feedback**: Visual flash + vibration + voice announcements
- **Small Screen Optimized**: Perfect for compact Android devices

### 🔊 Smart Announcements
When you reach each kilometer, the app announces:
- "The next target is kilometer 5. You have 5 minutes and 20 seconds left to reach the next target."
- "You are 1 minute behind schedule" (when running late)
- "Final kilometer! You have 6 minutes left to finish."

### ⚙️ Technical Features
- **Auto-save**: Progress saved every 10 seconds
- **Battery Optimized**: UI updates every 10 seconds (not every second)
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

## Usage

### Initial Setup
1. **Set Distance**: Tap distance field (default: 42.195 km marathon)
2. **Set Pace**: Tap pace field (default: 6:00 min/km)
3. **Start Run**: Press the START button

### During Your Run
1. **Monitor Progress**: Watch the color-coded time remaining
   - 🟢 Green: On pace or ahead
   - 🔴 Red: Behind schedule
2. **Mark Kilometers**: Press "GOT IT!" when you reach each km
3. **Listen**: Voice announcements provide progress updates
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
- **Permissions**: Vibration (for haptic feedback)
- **Audio**: Text-to-speech for voice announcements

### Dependencies
- `flutter`: SDK framework
- `shared_preferences`: Settings persistence
- `vibration`: Haptic feedback
- `flutter_tts`: Voice announcements

## Development

### Project Structure
```
lib/
├── main.dart              # App entry point
├── models/                # Data models
│   ├── app_settings.dart  # Distance/pace settings
│   └── running_session.dart # Session tracking
├── screens/               # UI screens
│   ├── start_screen.dart  # Initial setup
│   ├── main_screen.dart   # Running interface
│   └── completion_screen.dart # Results
├── services/              # Business logic
│   └── storage_service.dart # Data persistence
└── widgets/               # Reusable components
    ├── distance_dialog.dart
    └── pace_dialog.dart
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
