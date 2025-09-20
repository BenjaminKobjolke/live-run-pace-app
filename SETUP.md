# Live Run Pace App - Setup Instructions

## Initial Setup

After cloning this repository, you need to regenerate the platform directories:

```bash
# Navigate to project directory
cd live_run_pace_app

# Create Android and Web platforms
flutter create . --platforms android,web

# Get dependencies
flutter pub get

# Verify setup
flutter doctor
```

## Building the App

### For Android (Debug APK)
```bash
# Use the provided batch file (Windows)
./build_apk.bat

# Or manually
flutter build apk --debug
```

### For Web
```bash
flutter build web
```

## Development

### Running the App
```bash
# Android device/emulator
flutter run

# Web browser
flutter run -d chrome
```

### Platform Requirements
- **Android**: Minimum SDK 21 (Android 5.0)
- **Web**: Modern browsers with JavaScript enabled
- **Screen**: Optimized for 240x432 resolution (small Android devices)

## Features
- Pace tracking for running
- Kilometer target management
- Persistent storage of settings and sessions
- Visual and haptic feedback
- Session completion tracking