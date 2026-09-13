@echo off
REM نسخة احتياطية بضغطة واحدة - Double-cliquez pour sauvegarder
cd /d "%~dp0"
venv\Scripts\python.exe backup_online.py
echo.
pause
