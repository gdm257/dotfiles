@echo off
setlocal EnableExtensions

rem Extract every 7z pack in the payload into drivers\<basename>
rem PIDRV_SEVENZIP overrides the extractor path

set "PAYLOAD=%~dp0"
if not "%~1"=="" set "PAYLOAD=%~1"

set "SEVENZIP=%~dp0bin\7zr.exe"
if defined PIDRV_SEVENZIP set "SEVENZIP=%PIDRV_SEVENZIP%"

if not exist "%SEVENZIP%" (
    echo ERROR: 7-Zip standalone extractor not found: "%SEVENZIP%"
    echo ERROR: dependency: 7zr.exe ^(official standalone 7-Zip console extractor^)
    echo ERROR: download from https://www.7-zip.org/a/7zr.exe into bin\7zr.exe
    exit /b 2
)

set /a PACKS=0
set /a FAILED=0
for %%F in ("%PAYLOAD%\*.7z") do call :extract "%%~fF"
if %PACKS% EQU 0 (
    echo ERROR: no *.7z driver pack found in payload dir: "%PAYLOAD%"
    exit /b 2
)
echo done: %PACKS% pack(s), %FAILED% failed
exit /b %FAILED%

:extract
set /a PACKS+=1
if not exist "%PAYLOAD%\drivers\%~n1" mkdir "%PAYLOAD%\drivers\%~n1"
"%SEVENZIP%" x -y -o"%PAYLOAD%\drivers\%~n1" "%~1" >nul 2>nul
if errorlevel 1 (
    echo FAIL: %~nx1
    set /a FAILED+=1
) else (
    echo OK: %~nx1
)
exit /b 0
