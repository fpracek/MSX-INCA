@echo off
rem build + launch in openMSX (MSX1, plain 32K cartridge)
setlocal
set OMSX=E:\Dropbox\FAUSTO\SVILUPPI\MSX\EMULATORI\openMSX\openmsx.exe
cd /d "%~dp0"

call build.cmd
if errorlevel 1 exit /b 1

taskkill /IM openmsx.exe /F >nul 2>&1
start "" "%OMSX%" -machine Sony_HB-55P -carta "%~dp0build\kanji.rom"
