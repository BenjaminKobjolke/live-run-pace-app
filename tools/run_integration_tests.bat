@echo off
REM Runs integration tests via FVM. No integration tests exist yet; add them under integration_test/.
cd /d "%~dp0.."
if not exist "integration_test" (
  echo No integration_test/ directory yet - skipping.
  exit /b 0
)
call fvm flutter test integration_test
