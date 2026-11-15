@echo off
setlocal EnableExtensions

rem Self-check for build-drivers.cmd and pe-deploy.cmd. Builds fixture
rem payloads from fixtures/drvpath, runs the scripts, asserts behavior.

set "ROOT=%~dp0"
set "FIXTURES=%ROOT%..\fixtures\drvpath"
set "SZ=%ROOT%bin\7zr.exe"
set "WORK=%TEMP%\pdi-selfcheck"
set /a FAILED=0

if exist "%WORK%" rmdir /s /q "%WORK%"
mkdir "%WORK%\payload\packA"
mkdir "%WORK%\payload\packB"
copy /y "%FIXTURES%\packA\*" "%WORK%\payload\packA\" >nul
copy /y "%FIXTURES%\packB\*" "%WORK%\payload\packB\" >nul
echo decoy > "%WORK%\payload\fake.Scindex"
echo unrelated > "%WORK%\payload\notes.txt"
pushd "%WORK%\payload\packA"
"%SZ%" a -y "%WORK%\payload\packA.7z" * >nul
popd
pushd "%WORK%\payload\packB"
"%SZ%" a -y "%WORK%\payload\packB.7z" * >nul
popd

call :check_extract
call :check_idempotent
call :check_empty
call :check_bad_extractor
call :deploy_setup
call :check_deploy_scan_unique
call :check_deploy_scan_multi
call :check_deploy_bad_target
call :check_deploy_bad_inf
call :check_deploy_all_good
call :check_deploy_unattend
call :check_deploy_no_unattend
call :check_deploy_dism_missing
call :check_deploy_unattend_fail
call :check_deploy_unattend_fresh
call :deploy_teardown

echo.
echo self-check: %FAILED% failed assertion(s)
if exist "%WORK%" rmdir /s /q "%WORK%"
exit /b %FAILED%

:check_extract
call "%ROOT%build-drivers.cmd" "%WORK%\payload"
if errorlevel 1 goto :fail_extract
if not exist "%WORK%\payload\drivers\packA\foo.inf" goto :fail_extract
if not exist "%WORK%\payload\drivers\packA\foo.sys" goto :fail_extract
if not exist "%WORK%\payload\drivers\packA\foo.cat" goto :fail_extract
if not exist "%WORK%\payload\drivers\packB\bar.inf" goto :fail_extract
if not exist "%WORK%\payload\drivers\packB\bar.sys" goto :fail_extract
if not exist "%WORK%\payload\drivers\packB\bar.cat" goto :fail_extract
echo PASS [1] extract: exit 0 and both pack trees present
exit /b 0

:fail_extract
echo FAIL [1] extract: expected exit 0 and both pack trees under drivers\
set /a FAILED+=1
exit /b 0

:check_idempotent
dir /s /b "%WORK%\payload\drivers" > "%WORK%\listing-before.txt"
call "%ROOT%build-drivers.cmd" "%WORK%\payload" >nul
if errorlevel 1 goto :fail_idem
dir /s /b "%WORK%\payload\drivers" > "%WORK%\listing-after.txt"
fc "%WORK%\listing-before.txt" "%WORK%\listing-after.txt" >nul
if errorlevel 1 goto :fail_idem
echo PASS [2] idempotent: rerun exit 0, identical drivers tree
exit /b 0

:fail_idem
echo FAIL [2] idempotent: expected rerun exit 0 with identical drivers tree
set /a FAILED+=1
exit /b 0

:check_empty
mkdir "%WORK%\empty"
call "%ROOT%build-drivers.cmd" "%WORK%\empty" >nul
if errorlevel 1 (
    echo PASS [3] empty payload: nonzero exit
) else (
    echo FAIL [3] empty payload: expected nonzero exit
    set /a FAILED+=1
)
exit /b 0

:check_bad_extractor
set "PIDRV_SEVENZIP=%WORK%\missing-7zr.exe"
call "%ROOT%build-drivers.cmd" "%WORK%\payload" >nul
if errorlevel 1 (
    echo PASS [4] extractor missing: nonzero exit
) else (
    echo FAIL [4] extractor missing: expected nonzero exit
    set /a FAILED+=1
)
set "PIDRV_SEVENZIP="
exit /b 0

:deploy_setup
copy /y "%ROOT%pe-deploy.cmd" "%WORK%\payload\" >nul
set "DISMSTUB=%WORK%\dism-stub.cmd"
set "STUBLOG=%WORK%\dism-stub.log"
set "PIDRV_DISM=%DISMSTUB%"
set "PIDRV_STUB_LOG=%STUBLOG%"
set "ROOTS=%WORK%\roots"
set "PIDRV_SCAN_ROOTS=%ROOTS%"
(
echo @echo off
echo ^>^>"%%PIDRV_STUB_LOG%%" echo %%*
echo set "STUBARGS=%%*"
echo if not "%%STUBARGS:bad.inf=%%"=="%%STUBARGS%%" exit /b 1
echo if not "%%STUBARGS:/Get-Drivers=%%"=="%%STUBARGS%%" ^(
echo echo Total drivers: 7
echo ^)
echo exit /b 0
) > "%DISMSTUB%"
exit /b 0

:deploy_teardown
set "PIDRV_DISM="
set "PIDRV_STUB_LOG="
set "PIDRV_SCAN_ROOTS="
exit /b 0

:check_deploy_scan_unique
mkdir "%ROOTS%\D\Windows"
del "%STUBLOG%" 2>nul
call "%WORK%\payload\pe-deploy.cmd" >nul
if not "%errorlevel%"=="0" goto :fail_scan_unique
findstr /c:"/Image:" "%STUBLOG%" >nul || goto :fail_scan_unique
findstr /c:"%ROOTS%\D" "%STUBLOG%" >nul || goto :fail_scan_unique
echo PASS [5] scan unique: auto-selected %ROOTS%\D, stub hit with /Image
exit /b 0

:fail_scan_unique
echo FAIL [5] scan unique: expected exit 0 with stub /Image on %ROOTS%\D
set /a FAILED+=1
exit /b 0

:check_deploy_scan_multi
mkdir "%ROOTS%\E\Windows"
del "%STUBLOG%" 2>nul
if exist "%WORK%\payload\deploy-*.log" del "%WORK%\payload\deploy-*.log" >nul
call "%WORK%\payload\pe-deploy.cmd" >nul
if "%errorlevel%"=="0" goto :fail_scan_multi
if exist "%STUBLOG%" goto :fail_scan_multi
if exist "%WORK%\payload\deploy-*.log" goto :fail_scan_multi
echo PASS [6] scan multi: nonzero exit, stub not invoked, no writes
exit /b 0

:fail_scan_multi
echo FAIL [6] scan multi: expected nonzero exit without stub invocation or writes
set /a FAILED+=1
exit /b 0

:check_deploy_bad_target
mkdir "%WORK%\empty-target"
del "%STUBLOG%" 2>nul
call "%WORK%\payload\pe-deploy.cmd" "%WORK%\empty-target" >nul
if not "%errorlevel%"=="202" goto :fail_bad_target
if exist "%STUBLOG%" goto :fail_bad_target
echo PASS [7] bad target: exit 202, stub not invoked
exit /b 0

:fail_bad_target
echo FAIL [7] bad target: expected exit 202 without stub invocation
set /a FAILED+=1
exit /b 0

:deploy_payload
mkdir "%~1\drivers\packA"
mkdir "%~1\drivers\packB"
copy /y "%FIXTURES%\packA\*" "%~1\drivers\packA\" >nul
copy /y "%FIXTURES%\packB\*" "%~1\drivers\packB\" >nul
copy /y "%ROOT%pe-deploy.cmd" "%~1\" >nul
exit /b 0

:check_deploy_bad_inf
call :deploy_payload "%WORK%\payload-bad"
echo rem bad driver > "%WORK%\payload-bad\drivers\packA\bad.inf"
del "%STUBLOG%" 2>nul
call "%WORK%\payload-bad\pe-deploy.cmd" "%ROOTS%\D" >nul
if not "%errorlevel%"=="1" goto :fail_bad_inf
findstr /c:"FAIL: bad.inf" "%WORK%\payload-bad\deploy-*.log" >nul || goto :fail_bad_inf
findstr /c:"Get-Drivers" "%WORK%\payload-bad\deploy-*.log" >nul || goto :fail_bad_inf
findstr /c:"Total drivers: 7" "%WORK%\payload-bad\deploy-*.log" >nul || goto :fail_bad_inf
echo PASS [8] bad inf: exit 1, log has FAIL line and Get-Drivers section
exit /b 0

:fail_bad_inf
echo FAIL [8] bad inf: expected exit 1 with FAIL line and Get-Drivers in log
set /a FAILED+=1
exit /b 0

:check_deploy_all_good
del "%STUBLOG%" 2>nul
call "%WORK%\payload\pe-deploy.cmd" "%ROOTS%\D" >nul
if not "%errorlevel%"=="0" goto :fail_all_good
findstr /c:"foo.inf" "%STUBLOG%" >nul || goto :fail_all_good
findstr /c:"bar.inf" "%STUBLOG%" >nul || goto :fail_all_good
echo PASS [9] all good: exit 0, both infs handed to dism
exit /b 0

:fail_all_good
echo FAIL [9] all good: expected exit 0 with both infs passed to dism
set /a FAILED+=1
exit /b 0

:check_deploy_unattend
call :deploy_payload "%WORK%\payload-ua"
copy /y "%ROOT%unattend.xml" "%WORK%\payload-ua\" >nul
mkdir "%ROOTS%\UA\Windows\Panther"
del "%STUBLOG%" 2>nul
call "%WORK%\payload-ua\pe-deploy.cmd" "%ROOTS%\UA" >nul
if not "%errorlevel%"=="0" goto :fail_unattend
if not exist "%ROOTS%\UA\Windows\Panther\unattend.xml" goto :fail_unattend
echo PASS [10] unattend hook: copied into target Panther
exit /b 0

:fail_unattend
echo FAIL [10] unattend hook: expected unattend.xml in target Panther
set /a FAILED+=1
exit /b 0

:check_deploy_no_unattend
mkdir "%ROOTS%\NU\Windows"
del "%STUBLOG%" 2>nul
call "%WORK%\payload\pe-deploy.cmd" "%ROOTS%\NU" >nul
if not "%errorlevel%"=="0" goto :fail_no_unattend
if exist "%ROOTS%\NU\Windows\Panther" goto :fail_no_unattend
echo PASS [11] unattend absent: skipped, exit 0, no Panther created
exit /b 0

:fail_no_unattend
echo FAIL [11] unattend absent: expected exit 0 without Panther creation
set /a FAILED+=1
exit /b 0

:check_deploy_dism_missing
call :deploy_payload "%WORK%\payload-dm"
set "PIDRV_DISM=%WORK%\no-such-dism.cmd"
del "%STUBLOG%" 2>nul
call "%WORK%\payload-dm\pe-deploy.cmd" >nul
set "RC=%errorlevel%"
set "PIDRV_DISM=%DISMSTUB%"
if not "%RC%"=="201" goto :fail_dism_missing
if exist "%WORK%\payload-dm\deploy-*.log" goto :fail_dism_missing
if exist "%STUBLOG%" goto :fail_dism_missing
echo PASS [12] dism missing: exit 201, no log, stub not invoked
exit /b 0

:fail_dism_missing
set "PIDRV_DISM=%DISMSTUB%"
echo FAIL [12] dism missing: expected exit 201 without log or stub invocation
set /a FAILED+=1
exit /b 0

:check_deploy_unattend_fail
call :deploy_payload "%WORK%\payload-uf"
copy /y "%ROOT%unattend.xml" "%WORK%\payload-uf\" >nul
mkdir "%ROOTS%\UF\Windows"
echo blocked > "%ROOTS%\UF\Windows\Panther"
del "%STUBLOG%" 2>nul
call "%WORK%\payload-uf\pe-deploy.cmd" "%ROOTS%\UF" >nul
if not "%errorlevel%"=="206" goto :fail_unattend_fail
findstr /c:"ERROR: unattend copy failed" "%WORK%\payload-uf\deploy-*.log" >nul || goto :fail_unattend_fail
findstr /c:"OK: foo.inf" "%WORK%\payload-uf\deploy-*.log" >nul || goto :fail_unattend_fail
echo PASS [13] unattend copy fail: exit 206, error logged, injection results intact
exit /b 0

:fail_unattend_fail
echo FAIL [13] unattend copy fail: expected exit 206 with error logged and injection results intact
set /a FAILED+=1
exit /b 0

:check_deploy_unattend_fresh
call :deploy_payload "%WORK%\payload-un"
copy /y "%ROOT%unattend.xml" "%WORK%\payload-un\" >nul
mkdir "%ROOTS%\UN\Windows"
del "%STUBLOG%" 2>nul
call "%WORK%\payload-un\pe-deploy.cmd" "%ROOTS%\UN" >nul
if not "%errorlevel%"=="0" goto :fail_unattend_fresh
if not exist "%ROOTS%\UN\Windows\Panther" goto :fail_unattend_fresh
if not exist "%ROOTS%\UN\Windows\Panther\unattend.xml" goto :fail_unattend_fresh
echo PASS [14] unattend fresh image: Panther dir created, unattend.xml landed
exit /b 0

:fail_unattend_fresh
echo FAIL [14] unattend fresh image: expected Panther dir created with unattend.xml inside
set /a FAILED+=1
exit /b 0
