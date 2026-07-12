@echo off
setlocal
set "ROOT=%~dp0.."
set "APK=%ROOT%\build\app\outputs\flutter-apk\app-release.apk"

echo ========================================
echo Build and Upload Release APK
echo ========================================
echo.

echo [1/3] Building release APK...
cd /d "%ROOT%"
call fvm flutter build apk --release
if errorlevel 1 (
    echo.
    echo ERROR: Build failed!
    exit /b 1
)

if not exist "%APK%" (
    echo.
    echo ERROR: APK not found at "%APK%"
    exit /b 1
)

echo [2/3] Staging APK as live-run-pace.apk...
if not exist "%~dp0upload" mkdir "%~dp0upload"
copy /y "%APK%" "%~dp0upload\live-run-pace.apk" >nul
if errorlevel 1 (
    echo ERROR: Failed to stage APK!
    exit /b 1
)

echo [3/3] Uploading to FTP...
call "%~dp0upload_apk_to_ftp.bat"
if errorlevel 1 (
    echo.
    echo ERROR: Upload failed!
    exit /b 1
)

echo.
echo ========================================
echo Done.
echo ========================================
echo.
endlocal
