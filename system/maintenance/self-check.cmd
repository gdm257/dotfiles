@echo off
setlocal EnableExtensions

rem Self-check for maintenance run/check. Stubs task/reg/dism via MTN_* and
rem PATH seams; no real system changes.

set "ROOT=%~dp0..\.."
set "FIX=%ROOT%\fixtures\maintenance"
set "WORK=%TEMP%\mtn-selfcheck"
set "STUBS=%WORK%\stubs"
set "BASEPATH=%PATH%"
set /a FAILED=0

if exist "%WORK%" rmdir /s /q "%WORK%"
mkdir "%WORK%\stubs"
set "REG_STUB_STATE=%WORK%\reg-state.txt"
set "TASK_STUB_LOG=%WORK%\task-stub.log"
copy /y "%FIX%\task-stub.cmd" "%STUBS%\" >nul
copy /y "%FIX%\reg.bat" "%STUBS%\" >nul
copy /y "%FIX%\reg-stub.py" "%STUBS%\" >nul
copy /y "%FIX%\dism-stub.cmd" "%STUBS%\dism.cmd" >nul

call :check_replay_set
call :check_drift_restore
call :check_clean
call :check_drift
call :check_no_forbidden

echo.
echo self-check: %FAILED% failed assertion(s)
if exist "%WORK%" rmdir /s /q "%WORK%"
exit /b %FAILED%

:check_replay_set
set "MTN_TASK_BIN=%STUBS%\task-stub.cmd"
call "%ROOT%\system\maintenance\run.cmd" >nul 2>&1
set "RC=%errorlevel%"
set "MTN_TASK_BIN="
if not "%RC%"=="0" goto :fail_replay_set
fc "%FIX%\replay-expected.txt" "%TASK_STUB_LOG%" >nul
if errorlevel 1 goto :fail_replay_set
echo PASS [1] replay set: ordered coverage matches fixture list
exit /b 0

:fail_replay_set
echo FAIL [1] replay set: expected exit 0 and ordered match with replay-expected.txt
set /a FAILED+=1
exit /b 0

:check_drift_restore
> "%REG_STUB_STATE%" echo HKLM\SOFTWARE\Fixtures\Maintenance^|Drill=drifted
set "PATH=%STUBS%;%BASEPATH%"
python "%FIX%\receiver-run.py" "%FIX%\registry-item.json" "%WORK%\fail.log" "%ROOT%" >nul 2>&1
set "RC=%errorlevel%"
set "PATH=%BASEPATH%"
if not "%RC%"=="0" goto :fail_drift_restore
findstr /c:"HKLM\SOFTWARE\Fixtures\Maintenance|Drill=declared" "%REG_STUB_STATE%" >nul
if errorlevel 1 goto :fail_drift_restore
echo PASS [2] drift restore: registry receiver converges drifted value to declared
exit /b 0

:fail_drift_restore
echo FAIL [2] drift restore: expected exit 0 and declared value in stub state
set /a FAILED+=1
exit /b 0

:check_clean
mkdir "%WORK%\clean"
copy /y "%FIX%\registry.yaml" "%WORK%\clean\" >nul
copy /y "%FIX%\windows-features.yaml" "%WORK%\clean\" >nul
> "%REG_STUB_STATE%" echo HKLM\SOFTWARE\Fixtures\Maintenance^|Drill=declared
set "MTN_MANIFESTS_DIR=%WORK%\clean"
set "PATH=%STUBS%;%BASEPATH%"
call "%ROOT%\system\maintenance\check.cmd" >nul 2>&1
set "RC=%errorlevel%"
set "PATH=%BASEPATH%"
set "MTN_MANIFESTS_DIR="
if not "%RC%"=="0" goto :fail_clean
echo PASS [3] check clean: exit 0 when declared state matches
exit /b 0

:fail_clean
echo FAIL [3] check clean: expected exit 0, got %RC%
set /a FAILED+=1
exit /b 0

:check_drift
mkdir "%WORK%\drift"
copy /y "%FIX%\registry.yaml" "%WORK%\drift\" >nul
copy /y "%FIX%\windows-features.yaml" "%WORK%\drift\" >nul
echo   - { kind: windows-feature, feature: Fixture-Drift-off }>> "%WORK%\drift\windows-features.yaml"
> "%REG_STUB_STATE%" echo HKLM\SOFTWARE\Fixtures\Maintenance^|Drill=drifted
set "MTN_MANIFESTS_DIR=%WORK%\drift"
set "PATH=%STUBS%;%BASEPATH%"
call "%ROOT%\system\maintenance\check.cmd" >nul 2>&1
set "RC=%errorlevel%"
set "PATH=%BASEPATH%"
set "MTN_MANIFESTS_DIR="
if not "%RC%"=="10" goto :fail_drift
echo PASS [4] check drift: exit 10 on drifted registry value and feature state
exit /b 0

:fail_drift
echo FAIL [4] check drift: expected exit 10, got %RC%
set /a FAILED+=1
exit /b 0

:check_no_forbidden
findstr /ri "update per.user uninstall cleanup" "%FIX%\replay-expected.txt" >nul
if not errorlevel 1 goto :fail_no_forbidden
echo PASS [5] scope: replay set has no update/per-user/uninstall/cleanup entries
exit /b 0

:fail_no_forbidden
echo FAIL [5] scope: replay set contains forbidden entry
set /a FAILED+=1
exit /b 0
