@echo off
REM Build manuscripts-share for Windows.
REM Run this on a Windows machine with Python 3 installed.
REM
REM Usage:  build_windows.bat [version]
REM Output: dist\manuscripts-share.exe

setlocal
set VERSION=%~1
if "%VERSION%"=="" set VERSION=1.0

echo Building manuscripts-share v%VERSION% for Windows...

pip install --quiet pyinstaller aiohttp zeroconf

pyinstaller --onefile --console ^
    --name manuscripts-share ^
    --collect-all zeroconf ^
    --collect-all aiohttp ^
    share.py

echo.
echo Done: dist\manuscripts-share.exe
echo Distribute this .exe directly — no Python installation needed.
