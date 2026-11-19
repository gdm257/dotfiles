@echo off
setlocal EnableExtensions

rem Sysprep seal: refuse-level preflight, network off, sysprep /generalize
rem /oobe against system\unattend.xml with /shutdown, then sealed marker.
rem Seams: SYSP_SYSPREP SYSP_NETOFF SYSP_MARKER
rem Exit codes: 241 already sealed, 245 sysprep failed, 247 unattend
rem             missing, 248 network disconnect failed.

set "PAYLOAD=%~dp0"
for %%A in ("%PAYLOAD%..\..\") do set "SYSROOT=%%~fA"
set "UNATTEND=%SYSROOT%system\unattend.xml"
set "SYSPREP=%SystemRoot%\System32\Sysprep\sysprep.exe"
if defined SYSP_SYSPREP set "SYSPREP=%SYSP_SYSPREP%"
set "MARKER=%SystemRoot%\System32\Sysprep\sealed.marker"
if defined SYSP_MARKER set "MARKER=%SYSP_MARKER%"

if exist "%MARKER%" (
    echo ERROR: sealed marker present, machine already generalized: "%MARKER%"
    echo ERROR: run capture next, or rebuild from scratch to reseal
    exit /b 241
)
if not exist "%UNATTEND%" (
    echo ERROR: system\unattend.xml missing at "%UNATTEND%"
    exit /b 247
)

set "TS=%DATE%-%TIME%"
set "TS=%TS:/=-%"
set "TS=%TS::=-%"
set "TS=%TS:.=-%"
set "TS=%TS: =-%"
set "LOGDIR=%TEMP%\system"
if not exist "%LOGDIR%" mkdir "%LOGDIR%"
set "LOG=%LOGDIR%\sysprep-%TS%.log"

call :log "seal: marker %MARKER%, unattend %UNATTEND%"

if defined SYSP_NETOFF (
    call "%SYSP_NETOFF%" >> "%LOG%" 2>&1
) else (
    powershell -NoProfile -Command "Get-NetAdapter -Physical | Disable-NetAdapter -Confirm:$false" >> "%LOG%" 2>&1
)
if errorlevel 1 (
    call :log "FAIL: network disconnect"
    exit /b 248
)
call :log "OK: network disconnected"

call "%SYSPREP%" /generalize /oobe /unattend:%UNATTEND% /shutdown >> "%LOG%" 2>&1
if errorlevel 1 (
    call :log "FAIL: sysprep generalize"
    exit /b 245
)
call :log "OK: sysprep done"

> "%MARKER%" echo sealed %DATE% %TIME%
if errorlevel 1 (
    call :log "FAIL: sealed marker write"
    exit /b 245
)
call :log "OK: sealed marker written, machine will shut down"
exit /b 0

:log
echo(%~1
>>"%LOG%" echo(%~1
exit /b 0
