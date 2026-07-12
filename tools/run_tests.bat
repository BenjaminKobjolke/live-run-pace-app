@echo off
REM Runs the unit/widget test suite via FVM.
cd /d "%~dp0.."
call fvm flutter test
