@echo off
setlocal EnableExtensions

rem 维护检查：只读对比声明值与实机状态（registry 值、windows features），
rem 不施加任何变更。退出码 0=干净 / 10=漂移 / 232=工具缺失拒绝。

set "ROOT=%~dp0..\.."
set "TS=%DATE%-%TIME%"
set "TS=%TS:/=-%"
set "TS=%TS::=-%"
set "TS=%TS:.=-%"
set "TS=%TS: =-%"
set "LOGDIR=%TEMP%\system"
set "LOG=%LOGDIR%\maintenance-%TS%.log"
if not exist "%LOGDIR%" mkdir "%LOGDIR%"

pushd "%ROOT%"
python system\maintenance\check.py > "%LOG%" 2>&1
set "RC=%errorlevel%"
popd
type "%LOG%"
echo check log: "%LOG%"
exit /b %RC%
