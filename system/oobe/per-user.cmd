@echo off
setlocal EnableExtensions

rem OOBE per-user thin entry, run by the logon scheduled task and once by
rem FirstLogonCommands. Global lock dir serializes the two; per-user done
rem marker makes reruns no-ops. Exit codes: 0 done or skipped, 221 state
rem root unusable, 222 lock takeover failed, 223 replay failed, 224
rem done-marker write failed.

set "ROOT=%~dp0..\..\"
set "STATE=%SYSOOBE_STATE_ROOT%"
if not defined STATE set "STATE=%ProgramData%\system\oobe"
set "REPLAY=%SYSOOBE_REPLAY%"
if not defined REPLAY set "REPLAY=task manifests:system-peruser:install"
set "LOCK_WAIT=%SYSOOBE_LOCK_TIMEOUT%"
if not defined LOCK_WAIT set "LOCK_WAIT=120"

for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd-HHmmss"') do set "TS=%%i"
set "LOGDIR=%TEMP%\system"
set "LOG=%LOGDIR%\oobe-%TS%.log"
md "%LOGDIR%" 2>nul

md "%STATE%" 2>nul
if not exist "%STATE%\" (
    >>"%LOG%" echo ERROR: cannot create state root %STATE%
    exit /b 221
)

set /a WAITED=0
:lock
md "%STATE%\lock" >nul 2>&1 && goto :locked
if %WAITED% geq %LOCK_WAIT% goto :takeover
ping -n 2 127.0.0.1 >nul
set /a WAITED+=1
goto :lock
:takeover
>>"%LOG%" echo OK: lock takeover after %WAITED%s wait
rd /s /q "%STATE%\lock" >nul 2>&1
md "%STATE%\lock" >nul 2>&1 || goto :lock_fail
:locked

if exist "%STATE%\done-%USERNAME%.flag" (
    >>"%LOG%" echo OK: done-marker present for %USERNAME%, nothing to do
    rd /s /q "%STATE%\lock" >nul 2>&1
    exit /b 0
)

pushd "%ROOT%"
call %REPLAY%
set "RC=%errorlevel%"
popd
if not "%RC%"=="0" (
    >>"%LOG%" echo FAIL: per-user replay exited %RC%
    rd /s /q "%STATE%\lock" >nul 2>&1
    exit /b 223
)

>>"%STATE%\done-%USERNAME%.flag" echo done %TS%
if not exist "%STATE%\done-%USERNAME%.flag" (
    >>"%LOG%" echo ERROR: done-marker write failed for %USERNAME%
    rd /s /q "%STATE%\lock" >nul 2>&1
    exit /b 224
)
rd /s /q "%STATE%\lock" >nul 2>&1
>>"%LOG%" echo OK: per-user replay done for %USERNAME%
exit /b 0

:lock_fail
>>"%LOG%" echo ERROR: lock takeover failed under %STATE%
exit /b 222
