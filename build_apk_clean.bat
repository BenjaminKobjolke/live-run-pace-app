echo Building Flutter Debug APK...
echo.

cd /d "%~dp0"

echo Checking Flutter installation...
call flutter doctor

echo Setting Java heap size for Gradle...
set GRADLE_OPTS=-Xmx4g -XX:MaxMetaspaceSize=512m

echo Cleaning previous builds...
call flutter clean

echo Clearing ALL Gradle caches...
if exist "%USERPROFILE%\.gradle" (
    echo Removing entire .gradle folder...
    rmdir /s /q "%USERPROFILE%\.gradle"
)

echo Clearing local build cache...
if exist "build" (
    echo Removing build folder...
    rmdir /s /q "build"
)

echo Clearing Android build cache...
if exist "android\.gradle" (
    echo Removing android .gradle folder...
    rmdir /s /q "android\.gradle"
)

echo Upgrading Flutter...
call flutter upgrade

echo Getting dependencies...
call flutter pub get

echo Building debug APK with single architecture...
REM call flutter build apk --debug --target-platform android-arm64
call flutter build apk

echo.
if %ERRORLEVEL% EQU 0 (
    echo ✓ Build successful!
    echo APK location: build\app\outputs\flutter-apk\
    echo.
    echo Opening build folder...
	cd build\app\outputs\flutter-apk\
    REM explorer build\app\outputs\flutter-apk\
) else (
    echo ✗ Build failed with error code %ERRORLEVEL%
    echo.
    echo Troubleshooting tips:
    echo 1. Make sure you have enough free disk space
    echo 2. Close other applications to free up memory
    echo 3. Try running: flutter doctor
    echo 4. Try: flutter clean ^&^& flutter pub get
)

echo.
pause