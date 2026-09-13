@echo off
REM ============================================================
REM  SONO SGHAIER - Lancement automatique (Backend + Frontend)
REM  Double-cliquez sur ce fichier pour tout demarrer.
REM ============================================================
cd /d "%~dp0"

echo ============================================================
echo  1/2 Lancement du serveur FastAPI (port 8000)...
echo ============================================================
start "SONO Backend" venv\Scripts\python.exe -m uvicorn app.main:app --reload --port 8000

echo Attente du demarrage du serveur...
timeout /t 7 /nobreak >nul

echo ============================================================
echo  2/2 Lancement de l'application Flutter (Chrome)...
echo ============================================================
cd sono_app_frontend
flutter run -d chrome
