@echo off
setlocal EnableExtensions

rem Inject every INF under drivers\ into the offline Windows target
rem PIDRV_DISM overrides the dism command
rem PIDRV_SCAN_ROOTS replaces the scanned drive roots

set "PAYLOAD=%~dp0"

set "DISM=dism.exe"
if not defined PIDRV_DISM goto :dism_where
set "DISM=%PIDRV_DISM%"
if exist "%DISM%" goto :dism_ready
goto :dism_missing

:dism_where
where dism.exe >nul 2>nul || goto :dism_missing

:dism_ready

if not "%~1"=="" goto :target_arg
set /a CANDS=0
for %%L in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) do call :scan_letter %%L
if %CANDS% EQU 0 (
    echo ERROR: no candidate system drive, no volume has \Windows
    exit /b 203
)
if %CANDS% GTR 1 (
    echo ERROR: multiple candidate system drives, refusing to guess:
    for /l %%N in (1,1,%CANDS%) do call :show_cand %%N
    echo ERROR: rerun with an explicit target: pe-deploy.cmd [target-drive]
    exit /b 204
)
if defined PIDRV_SCAN_ROOTS set "TARGET=%PIDRV_SCAN_ROOTS%\%CAND1%\"
if not defined PIDRV_SCAN_ROOTS set "TARGET=%CAND1%:\"
goto :payload_check

:target_arg
set "TARGET=%~1"
if "%TARGET:~-1%"=="\" set "TARGET=%TARGET:~0,-1%"
if not exist "%TARGET%\Windows" (
    echo ERROR: target has no \Windows, refusing to touch: "%TARGET%"
    exit /b 202
)
if not "%TARGET:~-1%"=="\" set "TARGET=%TARGET%\"

:payload_check
dir /s /b "%PAYLOAD%drivers\*.inf" 2>nul | findstr "^" >nul || goto :no_inf

set "TS=%DATE%-%TIME%"
set "TS=%TS:/=-%"
set "TS=%TS::=-%"
set "TS=%TS:.=-%"
set "TS=%TS: =-%"
set "LOG=%PAYLOAD%deploy-%TS%.log"
set "DISMOUT=%TEMP%\pdi-dism-out.txt"

call :log "deploy: target %TARGET%"

set /a TOTAL=0
set /a FAILED=0
for /r "%PAYLOAD%drivers" %%I in (*.inf) do call :inject "%%~fI"

if exist "%PAYLOAD%unattend.xml" goto :unattend
call :log "unattend: absent in payload, skipped"
goto :inventory

:unattend
if not exist "%TARGET%Windows\Panther" mkdir "%TARGET%Windows\Panther"
copy /y "%PAYLOAD%unattend.xml" "%TARGET%Windows\Panther\unattend.xml" >nul
if errorlevel 1 goto :unattend_fail
call :log "unattend: hooked to %TARGET%Windows\Panther\unattend.xml"
goto :inventory

:unattend_fail
call :log "ERROR: unattend copy failed"
exit /b 206

:inventory
call :log "dism /Get-Drivers inventory:"
call "%DISM%" /Image:"%TARGET%" /Get-Drivers > "%DISMOUT%" 2>&1
call :flush_dism

call :log "done: %TOTAL% inf(s), %FAILED% failed"
exit /b %FAILED%

:scan_letter
if defined PIDRV_SCAN_ROOTS if exist "%PIDRV_SCAN_ROOTS%\%1\Windows" call :add_cand %1
if not defined PIDRV_SCAN_ROOTS if exist "%1:\" if exist "%1:\Windows" call :add_cand %1
exit /b 0

:add_cand
set /a CANDS+=1
set "CAND%CANDS%=%1"
exit /b 0

:show_cand
call set "C=%%CAND%1%%"
if defined PIDRV_SCAN_ROOTS (
    echo   candidate: %PIDRV_SCAN_ROOTS%\%C%\
) else (
    echo   candidate: %C%:
)
exit /b 0

:inject
set /a TOTAL+=1
call "%DISM%" /Image:"%TARGET%" /Add-Driver /Driver:"%~f1" > "%DISMOUT%" 2>&1
if not "%errorlevel%"=="0" goto :inject_fail
call :flush_dism
call :log "OK: %~nx1"
exit /b 0

:inject_fail
call :flush_dism
call :log "FAIL: %~nx1"
set /a FAILED+=1
exit /b 0

:flush_dism
type "%DISMOUT%"
>>"%LOG%" type "%DISMOUT%"
del "%DISMOUT%" 2>nul
exit /b 0

:no_inf
echo ERROR: no INF under "%PAYLOAD%drivers", run build-drivers.cmd first
exit /b 205

:dism_missing
echo ERROR: dism not resolvable, offline injection impossible
echo ERROR: the PE dism version MUST be greater than or equal to the target Windows build
echo ERROR: use a PE matching or exceeding the target OS build, newer PE for Win11 24H2+
exit /b 201

:log
echo(%~1
>>"%LOG%" echo(%~1
exit /b 0
