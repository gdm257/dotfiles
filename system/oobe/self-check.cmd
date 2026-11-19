@echo off
setlocal EnableExtensions

rem Self-check for the OOBE stage. Stub-only: no real scheduled task
rem registration, no real replay, state roots under %TEMP%.

set "ROOT=%~dp0..\..\"
set "WORK=%TEMP%\oobe-selfcheck"
set "TASK_CLI=%SYSOOBE_TASK%"
if not defined TASK_CLI set "TASK_CLI=task"
set /a FAILED=0

if exist "%WORK%" rmdir /s /q "%WORK%"
mkdir "%WORK%"

call :check_unattend
call :check_routing
call :check_mutex_done
call :check_replay_first
call :check_replay_idempotent
call :check_replay_fail
call :check_check_mode

echo.
echo self-check: %FAILED% failed assertion(s)
if exist "%WORK%" rmdir /s /q "%WORK%"
exit /b %FAILED%

:check_unattend
powershell -NoProfile -Command "try { [xml](Get-Content -Raw '%ROOT%system\unattend.xml') | Out-Null; exit 0 } catch { exit 1 }"
if errorlevel 1 goto :fail_unattend
findstr /c:"<LocalAccounts>" "%ROOT%system\unattend.xml" >nul || goto :fail_unattend
findstr /c:"<LogonCount>1</LogonCount>" "%ROOT%system\unattend.xml" >nul || goto :fail_unattend
findstr /c:"<FirstLogonCommands>" "%ROOT%system\unattend.xml" >nul || goto :fail_unattend
echo PASS [1] unattend: well-formed XML with LocalAccounts, AutoLogon Count=1, FirstLogonCommands
exit /b 0

:fail_unattend
echo FAIL [1] unattend: expected well-formed XML with LocalAccounts / AutoLogon Count=1 / FirstLogonCommands
set /a FAILED+=1
exit /b 0

:check_routing
findstr /c:"kind: logon-task" "%ROOT%manifests\system-oobe.yaml" >nul || goto :fail_routing
pushd "%ROOT%"
"%TASK_CLI%" --taskfile taskfile.d/manifest.yaml --dir . --dry logon-task:register "ITEM_JSON={\"kind\":\"logon-task\",\"name\":\"fixture\",\"cmd\":\"C:/per-user.cmd\",\"args\":\"--quiet\"}" > "%WORK%\routing.txt" 2>&1
set "RC=%errorlevel%"
popd
if not "%RC%"=="0" goto :fail_routing
findstr /c:"Register-ScheduledTask -TaskName \"fixture\"" "%WORK%\routing.txt" >nul || goto :fail_routing
findstr /c:"MSFT_TaskLogonTrigger" "%WORK%\routing.txt" >nul || goto :fail_routing
findstr /c:"S-1-5-32-545" "%WORK%\routing.txt" >nul || goto :fail_routing
findstr /c:"LogonType Interactive" "%WORK%\routing.txt" >nul || goto :fail_routing
findstr /c:"-Execute \"C:/per-user.cmd\" -Argument \"--quiet\"" "%WORK%\routing.txt" >nul || goto :fail_routing
echo PASS [2] logon-task: manifest item routed to receiver with any-user logon trigger and interactive group principal
exit /b 0

:fail_routing
echo FAIL [2] logon-task: expected receiver registration args for any-user logon task
set /a FAILED+=1
exit /b 0

:make_replay_stub
(
echo @echo off
echo echo run ^>^> "%WORK%\replay-count.txt"
) > "%WORK%\replay-stub.cmd"
(
echo @echo off
echo echo run ^>^> "%WORK%\replay-count.txt"
echo exit /b 1
) > "%WORK%\replay-fail.cmd"
exit /b 0

:check_mutex_done
call :make_replay_stub
set "SYSOOBE_STATE_ROOT=%WORK%\state-mutex"
set "SYSOOBE_REPLAY=%WORK%\replay-stub.cmd"
set "SYSOOBE_LOCK_TIMEOUT=2"
md "%SYSOOBE_STATE_ROOT%\lock"
echo done > "%SYSOOBE_STATE_ROOT%\done-%USERNAME%.flag"
call "%ROOT%system\oobe\per-user.cmd"
set "RC=%errorlevel%"
if not "%RC%"=="0" goto :fail_mutex_done
if exist "%WORK%\replay-count.txt" goto :fail_mutex_done
echo PASS [3] mutex: second entry under held lock takes over, sees done-marker, exits 0 without replay
call :oobe_teardown
exit /b 0

:fail_mutex_done
echo FAIL [3] mutex: expected exit 0 without replay when done-marker present
set /a FAILED+=1
call :oobe_teardown
exit /b 0

:check_replay_first
set "SYSOOBE_STATE_ROOT=%WORK%\state-first"
set "SYSOOBE_REPLAY=%WORK%\replay-stub.cmd"
set "SYSOOBE_LOCK_TIMEOUT=2"
call "%ROOT%system\oobe\per-user.cmd"
set "RC=%errorlevel%"
if not "%RC%"=="0" goto :fail_replay_first
if not exist "%SYSOOBE_STATE_ROOT%\done-%USERNAME%.flag" goto :fail_replay_first
findstr /c:"run" "%WORK%\replay-count.txt" >nul || goto :fail_replay_first
echo PASS [4] first entry: replays per-user manifest and writes done-marker
call :oobe_teardown
exit /b 0

:fail_replay_first
echo FAIL [4] first entry: expected replay run and done-marker written
set /a FAILED+=1
call :oobe_teardown
exit /b 0

:check_replay_idempotent
set "SYSOOBE_STATE_ROOT=%WORK%\state-first"
set "SYSOOBE_REPLAY=%WORK%\replay-stub.cmd"
set "SYSOOBE_LOCK_TIMEOUT=2"
call "%ROOT%system\oobe\per-user.cmd"
set "RC=%errorlevel%"
if not "%RC%"=="0" goto :fail_replay_idem
set /a RUNS=0
for /f %%c in ('find /c "run" ^< "%WORK%\replay-count.txt"') do set /a RUNS=%%c
if not "%RUNS%"=="1" goto :fail_replay_idem
echo PASS [5] idempotent: rerun exits 0 and does not replay again
call :oobe_teardown
exit /b 0

:fail_replay_idem
echo FAIL [5] idempotent: expected rerun exit 0 with exactly one replay run
set /a FAILED+=1
call :oobe_teardown
exit /b 0

:check_replay_fail
set "SYSOOBE_STATE_ROOT=%WORK%\state-fail"
set "SYSOOBE_REPLAY=%WORK%\replay-fail.cmd"
set "SYSOOBE_LOCK_TIMEOUT=2"
call "%ROOT%system\oobe\per-user.cmd"
set "RC=%errorlevel%"
if not "%RC%"=="223" goto :fail_replay_fail
if exist "%SYSOOBE_STATE_ROOT%\done-%USERNAME%.flag" goto :fail_replay_fail
echo PASS [6] replay failure: exit 223, no done-marker
call :oobe_teardown
exit /b 0

:fail_replay_fail
echo FAIL [6] replay failure: expected exit 223 without done-marker
set /a FAILED+=1
call :oobe_teardown
exit /b 0

:check_check_mode
call "%ROOT%system\oobe\check.cmd"
set "RC=%errorlevel%"
if not "%RC%"=="0" goto :fail_check_clean
mkdir "%WORK%\drift"
mkdir "%WORK%\drift\system"
echo ^<unattend/^> > "%WORK%\drift\system\unattend.xml"
dir /s /b "%WORK%\drift" > "%WORK%\drift-before.txt"
call "%ROOT%system\oobe\check.cmd" "%WORK%\drift"
set "RC2=%errorlevel%"
if not "%RC2%"=="10" goto :fail_check_drift
dir /s /b "%WORK%\drift" > "%WORK%\drift-after.txt"
fc "%WORK%\drift-before.txt" "%WORK%\drift-after.txt" >nul || goto :fail_check_drift
echo PASS [7] check: exit 0 clean, exit 10 drift, reports only without writes
exit /b 0

:fail_check_clean
echo FAIL [7] check: expected exit 0 on repo tree
set /a FAILED+=1
exit /b 0

:fail_check_drift
echo FAIL [7] check: expected exit 10 on drift fixture with no writes
set /a FAILED+=1
exit /b 0

:oobe_teardown
set "SYSOOBE_STATE_ROOT="
set "SYSOOBE_REPLAY="
set "SYSOOBE_LOCK_TIMEOUT="
exit /b 0
