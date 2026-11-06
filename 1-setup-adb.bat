@echo off
cd /d "%~dp0"
echo Downloading Google's Android Platform Tools (adb) from dl.google.com ...
curl.exe -L -o platform-tools.zip https://dl.google.com/android/repository/platform-tools-latest-windows.zip
if errorlevel 1 ( echo Download failed. & pause & exit /b 1 )
tar -xf platform-tools.zip
platform-tools\adb.exe version
echo.
echo Done. Next: run 2-connect-and-scan.bat
pause
