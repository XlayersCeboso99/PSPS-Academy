@echo off
cd /d "%~dp0.."
powershell -NoProfile -ExecutionPolicy Bypass -File "tool\instalar_android.ps1"
echo.
pause
