@echo off
echo Setting up Live Run Pace App...
echo.

cd /d "%~dp0"

echo Checking Flutter installation...
call flutter doctor

echo.
echo Creating Android and Web platforms...
call flutter create . --platforms android,web

echo.
echo Getting dependencies...
call flutter pub get

echo.
if %ERRORLEVEL% EQU 0 (
    echo ✓ Setup completed successfully!
    echo.
    echo You can now:
    echo - Run on Android: flutter run
    echo - Run on Web: flutter run -d chrome
    echo - Build APK: build_apk.bat
    echo.
) else (
    echo ✗ Setup failed with error code %ERRORLEVEL%
    echo.
    echo Please check:
    echo 1. Flutter is properly installed
    echo 2. You have internet connection
    echo 3. Run: flutter doctor
)

echo.
pause