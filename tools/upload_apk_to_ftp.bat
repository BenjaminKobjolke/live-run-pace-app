@echo off
setlocal
set "FTPSYNC=D:\GIT\BenjaminKobjolke\ftp-sync"
set "SETTINGS=%~dp0ftp_sync.ini"
set "STAGING=%~dp0upload"

if not exist "%SETTINGS%" (
    echo ERROR: "%SETTINGS%" not found.
    echo Copy ftp_sync_example.ini to ftp_sync.ini and fill in the FTP password.
    pause
    exit /b 1
)

if not exist "%STAGING%\live-run-pace.apk" (
    echo ERROR: "%STAGING%\live-run-pace.apk" not found. Run build_and_upload_release.bat first.
    exit /b 1
)

pushd "%FTPSYNC%"
uv run python main.py "%SETTINGS%" --local-dir "%STAGING%"
set "RC=%errorlevel%"
popd
exit /b %RC%
