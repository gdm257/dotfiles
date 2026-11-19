@echo off
setlocal EnableExtensions

rem 维护重放：按 taskfile.yaml 声明顺序重放全部 Windows 机器级 manifest 任务。
rem 收录规则：platforms 含 windows 且动作是 install/apply/set；排除 per-user
rem 清单（manifests/system-peruser.yaml）、uninstall、update、Windows Update
rem 与系统清理（spec：维护无聚合选择机制，清单静态维护）。

set "ROOT=%~dp0..\.."
set "TS=%DATE%-%TIME%"
set "TS=%TS:/=-%"
set "TS=%TS::=-%"
set "TS=%TS:.=-%"
set "TS=%TS: =-%"
set "LOG=%LOGDIR%\maintenance-%TS%.log"
if not exist "%LOGDIR%" mkdir "%LOGDIR%"
echo maintenance run %TS%>> "%LOG%"

set "TASKBIN=%MTN_TASK_BIN%"
if not defined TASKBIN set "TASKBIN=task"

call :replay manifests:app:audio:install || goto :fail
call :replay manifests:app:devops:install || goto :fail
call :replay manifests:app:downloader:install || goto :fail
call :replay manifests:app:file:install || goto :fail
call :replay manifests:app:kernel:install || goto :fail
call :replay manifests:app:layer:install || goto :fail
call :replay manifests:app:network:install || goto :fail
call :replay manifests:app:np:install || goto :fail
call :replay manifests:app:picture:install || goto :fail
call :replay manifests:app:process:install || goto :fail
call :replay manifests:app:shell:install || goto :fail
call :replay manifests:app:text:install || goto :fail
call :replay manifests:app:toolbox:install || goto :fail
call :replay manifests:app:video:install || goto :fail
call :replay manifests:choco:install || goto :fail
call :replay manifests:lockdown:apply || goto :fail
call :replay manifests:permissions:apply || goto :fail
call :replay manifests:registry:set || goto :fail
call :replay manifests:scoop-bucket:install || goto :fail
call :replay manifests:scoop-config:install || goto :fail
call :replay manifests:windows-features:set || goto :fail
call :replay manifests:winget:install || goto :fail
call :replay manifests:wsl:install || goto :fail

echo maintenance run converged, log: "%LOG%"
exit /b 0

:replay
echo === task %~1
echo === task %~1>> "%LOG%"
pushd "%ROOT%"
call "%TASKBIN%" %~1 >> "%LOG%" 2>&1
set "RC=%errorlevel%"
popd
if not "%RC%"=="0" echo FAIL: task %~1 exited %RC%>> "%LOG%"
exit /b %RC%

:fail
echo FAIL: maintenance replay stopped, see "%LOG%" 1>&2
exit /b 231
