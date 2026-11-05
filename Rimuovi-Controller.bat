@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Rimuovi-Controller.ps1"
timeout /t 3 >nul
