# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Live Run Pace App is a Flutter application designed for runners to track their pace and kilometer targets during runs. The app is optimized for small screen Android devices (240x432 resolution) and provides real-time pace feedback with multi-modal alerts (visual, haptic, audio).

## Development Commands

### Initial Setup
```bash
# After cloning, regenerate platform directories
install.bat                    # Windows setup script
# OR manually:
flutter create . --platforms android,web
flutter pub get
```

### Running the App
```bash
flutter run                    # Android device/emulator
flutter run -d chrome          # Web browser
```

### Building
```bash
build_apk_quick.bat            # Quick debug APK build
build_apk_clean.bat            # Clean build with full cache clearing
flutter build apk             # Manual debug APK
flutter build web             # Web build
```

### Icon Generation
```bash
flutter pub run flutter_launcher_icons:main    # Generate app icons from assets/icons/icon.png
```

### Development Tools
```bash
flutter clean && flutter pub get    # Clean and refresh dependencies
flutter doctor                     # Check Flutter installation
```

## Architecture Overview

### Core Application Flow
1. **App Startup**: `AppLoader` checks for existing active sessions and routes accordingly
2. **Session Recovery**: Automatically resumes interrupted runs from persistent storage
3. **Settings Management**: Dual-pace system (target pace + max pace for when behind schedule)
4. **Audio Integration**: Complex TTS + custom MP3 + AIMP music player coordination

### Key Architectural Patterns

**Singleton Storage Service**: `StorageService.instance` manages all data persistence using SharedPreferences with JSON serialization.

**Session State Management**: Running sessions persist across app restarts with automatic recovery. The app maintains both active session state and session history.

**Audio Focus Architecture**: Multi-layered audio management:
- `TtsSpeaker` coordinates TTS announcements, custom MP3 playback, and audio focus
- Android native `MainActivity.kt` handles AIMP music player integration via method channels
- `audio_session` package manages proper audio interruption/resumption with other apps

**Dual-Pace System**: Uses both target pace and max pace to handle scenarios where runners fall behind schedule, switching to more aggressive pacing when needed.

### Data Models

**AppSettings**: Distance, target pace, and max pace configuration with time calculation utilities.

**RunningSession**: Tracks kilometer progress with `KilometerTarget` objects, calculates pace status (ahead/behind/on schedule), and manages session completion state.

**TtsSettings**: Comprehensive audio configuration including TTS parameters, multiple MP3 file paths with random selection, AIMP integration toggles, and gesture controls.

### Critical Android Integration

**Native Method Channels**: `com.yourapp.live_run_pace/aimp` channel in `MainActivity.kt` provides:
- `toggleAimp`: Alternates between play/pause for AIMP music player
- `resumeAimp`: Resumes AIMP after TTS announcements

**Permission Handling**: Complex Android version-specific permission logic in `tts_settings_dialog.dart`:
- Android 13+: Uses `Permission.audio`
- Android 12-: Uses `Permission.storage`
- Special handling for Android 8 file picker limitations

**File Management**: Supports both individual file selection and recursive folder scanning for audio files (MP3/WAV/M4A).

### UI Architecture

**Small Screen Optimization**: Designed for 240x432 resolution with space-efficient layouts and gesture controls.

**Gesture System**:
- Single tap main screen: AIMP play/pause toggle
- Double tap main screen: Mark kilometer completion (alternative to "GOT IT!" button)

**Color-Coded Feedback**: Green/red time displays based on pace status with synchronized visual flash and vibration.

### Audio Workflow

1. **TTS Announcement**: "The next target is kilometer X. You have Y minutes left..."
2. **Custom MP3**: Random selection from user's audio files plays after TTS
3. **Audio Focus Management**: Pauses other apps during announcements, resumes after
4. **AIMP Integration**: Automatically resumes music player after announcement sequence

## Platform-Specific Notes

### Android Requirements
- Minimum SDK 21 (Android 5.0+)
- Permissions: Storage/Audio, Vibration
- AIMP player integration requires AIMP app installation

### File Structure Considerations
- Platform directories (`android/`, `web/`) are git-ignored and regenerated via `install.bat`
- Custom app icons placed in `assets/icons/icon.png` and generated via flutter_launcher_icons
- Audio files supported: MP3, WAV, M4A with recursive folder scanning

### Testing and Debugging
The app includes extensive logging for audio focus management, TTS events, and AIMP integration. Use ADB logcat filtering for audio-related debugging:
```bash
adb logcat | findstr "Audio\|TTS\|MP3\|AIMP\|flutter"
```

## Common Development Patterns

When working with this codebase:
- Always check session state recovery in new features
- Audio features require careful focus management coordination
- UI changes should consider 240x432 screen constraints
- File operations need Android version-specific permission handling
- Settings changes should include JSON serialization support for persistence