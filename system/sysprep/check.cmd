@echo off
setlocal EnableExtensions

rem Report-only sysprep stage check. Exit codes: 0 not sealed (ready to
rem seal), 10 sealed (capture pending), 247 unattend missing or malformed.

set "UNATTEND=%~dp0..\unattend.xml"
set "MARKER=%SystemRoot%\System32\Sysprep\sealed.marker"
if defined SYSP_MARKER set "MARKER=%SYSP_MARKER%"

if not exist "%UNATTEND%" (
    echo ERROR: system\unattend.xml missing at "%UNATTEND%"
    exit /b 247
)
powershell -NoProfile -Command "try { [xml](Get-Content -Raw '%UNATTEND%') | Out-Null; exit 0 } catch { exit 1 }"
if errorlevel 1 (
    echo ERROR: system/unattend.xml is not well-formed XML
    exit /b 247
)
if exist "%MARKER%" (
    echo SEALED: marker present, capture pending: "%MARKER%"
    exit /b 10
)
echo OK: not sealed, ready to seal
exit /b 0
