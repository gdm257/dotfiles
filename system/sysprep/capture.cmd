@echo off
setlocal EnableExtensions

rem Offline image capture, run from PE against the sealed target volume.
rem Seams: SYSP_DISM SYSP_MARKER SYSP_VOLUMES SYSP_BOOT SYSP_DATE SYSP_BUILD
rem Exit codes: 242 not sealed, 243 wim exists, 244 no eligible partition,
rem             246 dism capture failed, 249 bad target or build unreadable.

set "PAYLOAD=%~dp0"

if "%~1"=="" (
    echo ERROR: usage: capture.cmd target-drive
    exit /b 249
)
set "TARGET=%~1"
if "%TARGET:~-1%"=="\" set "TARGET=%TARGET:~0,-1%"
if not exist "%TARGET%\Windows" (
    echo ERROR: target has no \Windows, refusing to capture: "%TARGET%"
    exit /b 249
)

set "MARKER=%TARGET%\Windows\System32\Sysprep\sealed.marker"
if defined SYSP_MARKER set "MARKER=%SYSP_MARKER%"
if not exist "%MARKER%" (
    echo ERROR: sealed marker absent, run seal first: "%MARKER%"
    exit /b 242
)

set "BUILD="
if defined SYSP_BUILD (set "BUILD=%SYSP_BUILD%") else call :target_build
if not defined BUILD (
    echo ERROR: target CurrentBuild unreadable, refusing to name wim
    exit /b 249
)

set "BOOTVOL=%SystemDrive%"
if defined SYSP_BOOT set "BOOTVOL=%SYSP_BOOT%"
set "VOLFILE=%TEMP%\sysp-volumes.txt"
if defined SYSP_VOLUMES set "VOLFILE=%SYSP_VOLUMES%"
if not defined SYSP_VOLUMES (
    powershell -NoProfile -Command "Get-Volume | Where-Object { $_.DriveLetter -and $_.DriveType -eq 'Fixed' } | ForEach-Object { '{0}: {1} fixed' -f $_.DriveLetter, [math]::Floor($_.SizeRemaining/1MB) }" > "%VOLFILE%" 2>nul
)
set /a BEST=0
set "CHOICE="
for /f "tokens=1-3" %%A in ('type "%VOLFILE%"') do call :consider %%A %%B %%C
if not defined CHOICE (
    echo ERROR: no eligible local partition for capture
    exit /b 244
)

if exist "%CHOICE%\install-*.wim" (
    echo ERROR: install wim already present on %CHOICE%, refusing overwrite
    exit /b 243
)

set "DATE8="
if defined SYSP_DATE (set "DATE8=%SYSP_DATE%") else for /f %%D in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd"') do set "DATE8=%%D"

set "TS=%DATE%-%TIME%"
set "TS=%TS:/=-%"
set "TS=%TS::=-%"
set "TS=%TS:.=-%"
set "TS=%TS: =-%"
set "LOG=%PAYLOAD%capture-%TS%.log"
set "WIM=%CHOICE%\install-%DATE8%-%BUILD%.wim"

call :log "capture: target %TARGET%, wim %WIM%"

set "DISM=dism.exe"
if defined SYSP_DISM set "DISM=%SYSP_DISM%"
call "%DISM%" /Capture-Image /ImageFile:"%WIM%" /CaptureDir:"%TARGET%\" /Name:"install-%DATE8%-%BUILD%" >> "%LOG%" 2>&1
if errorlevel 1 (
    call :log "FAIL: dism capture"
    exit /b 246
)
call :log "OK: captured %WIM%"
exit /b 0

:consider
if /i not "%~3"=="fixed" exit /b 0
if /i "%~1"=="%BOOTVOL%" exit /b 0
if /i "%~1"=="%TARGET%" exit /b 0
if %~2 LEQ %BEST% exit /b 0
set /a BEST=%~2
set "CHOICE=%~1"
exit /b 0

:target_build
reg load HKLM\SYSP_TSYS "%TARGET%\Windows\System32\config\SOFTWARE" >nul 2>nul
if errorlevel 1 exit /b 0
for /f "tokens=3" %%B in ('reg query "HKLM\SYSP_TSYS\Microsoft\Windows NT\CurrentVersion" /v CurrentBuild 2^>nul ^| find "CurrentBuild"') do set "BUILD=%%B"
reg unload HKLM\SYSP_TSYS >nul 2>nul
exit /b 0

:log
echo(%~1
>>"%LOG%" echo(%~1
exit /b 0
