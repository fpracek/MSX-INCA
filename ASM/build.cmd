@echo off
setlocal
set SJASM="E:\Dropbox\FAUSTO\SVILUPPI\MSX\sjasmplus-1.20.3.win\sjasmplus.exe"
if not exist build mkdir build
%SJASM% --sym=build\kanji.sym --lst=build\kanji.lst kanji.asm
if errorlevel 1 goto err
echo.
echo ROM built: build\kanji.rom
goto :eof
:err
echo.
echo BUILD FAILED
exit /b 1
