@echo off
REM FloodFax AI - Windows launcher.
REM Builds the web app and serves the whole thing (UI + API + PDFs) from one
REM process on one port: http://localhost:8000
REM
REM Just double-click this file, or run  run.bat  in Command Prompt.

setlocal enabledelayedexpansion
cd /d "%~dp0"

set PORT=8000
if not "%~1"=="" set REBUILD=%~1

echo.
echo === FloodFax AI ===
echo.

REM --- Check prerequisites ---------------------------------------------------
where python >nul 2>nul
if errorlevel 1 (
  echo [X] Python is not installed or not on PATH.
  echo     Install Python 3.11+ from https://www.python.org/downloads/
  echo     ^(tick "Add Python to PATH" during install^), then reopen this window.
  pause
  exit /b 1
)
where node >nul 2>nul
if errorlevel 1 (
  echo [X] Node.js is not installed or not on PATH.
  echo     Install Node 20+ from https://nodejs.org/ , then reopen this window.
  pause
  exit /b 1
)

REM --- Frontend: build to static files ---------------------------------------
cd frontend
if not exist "node_modules\" (
  echo [*] Installing frontend dependencies ^(first run, takes a minute^)...
  call npm install
  if errorlevel 1 ( echo [X] npm install failed. & pause & exit /b 1 )
)
if /i "%REBUILD%"=="--rebuild" ( set DOBUILD=1 )
if not exist "out\index.html" ( set DOBUILD=1 )
if defined DOBUILD (
  echo [*] Building the web app...
  call npm run build
  if errorlevel 1 ( echo [X] Build failed. & pause & exit /b 1 )
  echo [OK] Web app built.
) else (
  echo [OK] Web app already built ^(run  run.bat --rebuild  to refresh^).
)
cd ..

REM --- Backend: venv + deps + env --------------------------------------------
cd backend
if not exist ".venv\" (
  echo [*] Creating Python virtual environment...
  python -m venv .venv
)
call .venv\Scripts\activate.bat
echo [*] Installing backend dependencies...
python -m pip install --quiet --upgrade pip
python -m pip install --quiet -r requirements.txt
if errorlevel 1 ( echo [X] pip install failed. & pause & exit /b 1 )
if not exist ".env" (
  copy /y .env.example .env >nul
  echo [*] Wrote backend\.env from template.
)

REM --- Serve everything from one process -------------------------------------
echo.
echo [OK] Starting FloodFax on http://localhost:%PORT%   ^(API docs: /docs^)
echo      Open that address in your browser.
echo      Press Ctrl-C in this window to stop.
echo.
python -m uvicorn app.main:app --host 0.0.0.0 --port %PORT%

pause
