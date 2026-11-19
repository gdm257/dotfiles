@echo off
setlocal EnableExtensions

rem Report-only OOBE stage check. Exit codes: 0 clean, 10 drift,
rem 221 unattend.xml not well-formed XML. Applies no changes.

set "ROOT=%~dp0..\..\"
if not "%~1"=="" set "ROOT=%~1\"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"
set "ROOT=%ROOT%\"
set /a DRIFT=0

powershell -NoProfile -Command "try { [xml](Get-Content -Raw '%ROOT%system\unattend.xml') | Out-Null; exit 0 } catch { exit 1 }"
if errorlevel 1 (
    echo ERROR: system/unattend.xml is not well-formed XML
    exit /b 221
)

findstr /c:"<LocalAccounts>" "%ROOT%system\unattend.xml" >nul || call :drift "unattend missing LocalAccounts"
findstr /c:"<LogonCount>1</LogonCount>" "%ROOT%system\unattend.xml" >nul || call :drift "unattend missing AutoLogon LogonCount 1"
findstr /c:"<FirstLogonCommands>" "%ROOT%system\unattend.xml" >nul || call :drift "unattend missing FirstLogonCommands"
findstr /c:"logon-task" "%ROOT%manifests\system-oobe.yaml" >nul || call :drift "system-oobe manifest missing logon-task item"
if not exist "%ROOT%system\oobe\per-user.cmd" call :drift "per-user entry missing"

if %DRIFT% gtr 0 exit /b 10
echo OK: oobe stage clean
exit /b 0

:drift
echo DRIFT: %~1
set /a DRIFT+=1
exit /b 0
