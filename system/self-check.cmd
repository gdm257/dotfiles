@echo off
setlocal EnableExtensions

rem Root thin entry: runs each module self-check in stage order, then a
rem cheap exit-code interval guard over stage scripts. Exit code = total
rem failed assertions.

set "ROOT=%~dp0"
set /a FAILED=0

call :suite pe
call :suite audit
call :suite oobe
call :suite sysprep
call :suite maintenance
call :check_exit_codes

echo.
echo self-check: %FAILED% failed assertion(s)
exit /b %FAILED%

:suite
echo.
echo === %~1
call "%ROOT%%~1\self-check.cmd"
set "RC=%errorlevel%"
if %RC% GTR 0 set /a FAILED+=%RC%
exit /b 0

:check_exit_codes
echo.
echo === exit-code intervals
call :stage_codes pe 201 209
call :stage_codes audit 211 219
call :stage_codes oobe 221 229
call :stage_codes maintenance 231 239
call :stage_codes sysprep 241 249
exit /b 0

:stage_codes
set /a BAD=0
set "SMIN=%~2"
set "SMAX=%~3"
for /f "delims=" %%L in ('findstr /r /c:"exit /b 2[0-9][0-9]" "%ROOT%%~1\*.cmd" 2^>nul') do (
    set "LINE=%%L"
    call :check_code
)
if %BAD% GTR 0 (
    echo FAIL: %~1 uses 2xx exit code outside [%~2,%~3]
    set /a FAILED+=1
) else (
    echo PASS: %~1 2xx exit codes within [%~2,%~3]
)
exit /b 0

:check_code
call set "CODE=%%LINE:*exit /b =%%"
if %CODE% LSS %SMIN% set /a BAD+=1
if %CODE% GTR %SMAX% set /a BAD+=1
exit /b 0
