@echo off
cd /d "%~dp0"
echo ===============================
echo   Delta Auth API Server
echo ===============================
echo.
echo Starting API server...
python api\main.py
pause
