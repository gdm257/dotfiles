@echo off
setlocal EnableExtensions

rem Self-check for audit apply.cmd. Stub seams live in fixtures/, log paths and
rem outcome switches come from SC_* env, real system state untouched.

set "ROOT=%~dp0..\.."
set "FIXTURES=%~dp0fixtures"
set "WORK=%TEMP%\sysad-selfcheck"
set /a FAILED=0

if exist "%WORK%" rmdir /s /q "%WORK%"
mkdir "%WORK%"
set "SC_PS_LOG=%WORK%\ps.log"
set "SC_TASK_LOG=%WORK%\task.log"
set "SC_REG_LOG=%WORK%\reg.log"
set "SC_CURL_LOG=%WORK%\curl.log"
set "APPLY=%~dp0apply.cmd"

set "SYSAD_POWERSHELL=%FIXTURES%\ps-stub.cmd"
set "SYSAD_TASK=%FIXTURES%\task-stub.cmd"
set "SYSAD_REG=%FIXTURES%\reg-stub.cmd"
set "SYSAD_CURL=%FIXTURES%\curl-stub.cmd"
set "SYSAD_NTUSER=%WORK%\NTUSER.DAT"
set "SYSAD_DPDIR=%WORK%\no-dpsrc"
set "SYSAD_DPDEST=%WORK%\dpdest"
set "SYSAD_MSIXURL=https://fixture.invalid/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
type nul > "%SYSAD_NTUSER%"

call :check_bootstrap_register
call :check_msixbundle
call :check_scope
call :check_msix_offender
call :check_rerun
call :check_check_drift
call :check_check_refusal
call :check_check_registry_clean

echo.
echo self-check: %FAILED% failed assertion(s)
if exist "%WORK%" rmdir /s /q "%WORK%"
exit /b %FAILED%

:check_bootstrap_register
set "SYSAD_WINGET=%WORK%\no-winget.exe"
del "%SC_PS_LOG%" 2>nul
del "%SC_CURL_LOG%" 2>nul
call "%APPLY%" > "%WORK%\run1.txt" 2>&1
set "RC1=%errorlevel%"
if not "%RC1%"=="0" goto :fail_bootstrap_register
findstr /c:"appx.ps1 probe" "%SC_PS_LOG%" >nul || goto :fail_bootstrap_register
findstr /c:"appx.ps1 register" "%SC_PS_LOG%" >nul || goto :fail_bootstrap_register
if exist "%SC_CURL_LOG%" goto :fail_bootstrap_register
echo PASS [1] bootstrap: winget unregistered, register path taken, no msixbundle
exit /b 0
:fail_bootstrap_register
echo FAIL [1] bootstrap: expected exit 0, probe+register hit, no curl
set /a FAILED+=1
exit /b 0

:check_msixbundle
set "SC_PROBE_FAIL=1"
del "%SC_PS_LOG%" 2>nul
del "%SC_CURL_LOG%" 2>nul
call "%APPLY%" > "%WORK%\run2.txt" 2>&1
set "RC2=%errorlevel%"
set "SC_PROBE_FAIL="
if not "%RC2%"=="0" goto :fail_msixbundle
findstr /c:"Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" "%SC_CURL_LOG%" >nul || goto :fail_msixbundle
findstr /c:"appx.ps1 install" "%SC_PS_LOG%" >nul || goto :fail_msixbundle
findstr /c:"appx.ps1 register" "%SC_PS_LOG%" >nul || goto :fail_msixbundle
echo PASS [2] msixbundle: App Installer missing triggers download fallback then register
exit /b 0
:fail_msixbundle
set "SC_PROBE_FAIL="
echo FAIL [2] msixbundle: expected download, install and register via stubs
set /a FAILED+=1
exit /b 0

:check_scope
pushd "%ROOT%"
task --taskfile taskfile.d\manifest.yaml --dir . --dry dispatch MANIFEST=manifests/system-audit.yaml CALLS=winget-app=winget:install > "%WORK%\dry-scope.txt" 2>&1
task --taskfile taskfile.d\manifest.yaml --dir . --dry dispatch MANIFEST=manifests/winget.yaml CALLS=winget-app=winget:install > "%WORK%\dry-plain.txt" 2>&1
popd
findstr /c:"--scope machine" "%WORK%\dry-scope.txt" >nul || goto :fail_scope
findstr /c:"--scope" "%WORK%\dry-plain.txt" >nul && goto :fail_scope
echo PASS [3] scope: receiver emits --scope machine only when declared
exit /b 0
:fail_scope
echo FAIL [3] scope: expected --scope machine with field, none without
set /a FAILED+=1
exit /b 0

:check_msix_offender
set "SYSAD_WINGET=%FIXTURES%\winget-ok.cmd"
set "SC_MSIX_BAD=1"
call "%APPLY%" > "%WORK%\run3.txt" 2>&1
set "RC3=%errorlevel%"
set "SC_MSIX_BAD="
if not "%RC3%"=="211" goto :fail_msix_offender
findstr /c:"MSIX: Fake.BadApp" "%WORK%\run3.txt" >nul || goto :fail_msix_offender
findstr /c:"FAIL: unprovisioned" "%WORK%\run3.txt" >nul || goto :fail_msix_offender
echo PASS [4] msix self-check: unprovisioned per-user package fails with exit 211
exit /b 0
:fail_msix_offender
set "SC_MSIX_BAD="
echo FAIL [4] msix self-check: expected exit 211 listing the fake package
set /a FAILED+=1
exit /b 0

:check_rerun
del "%SC_PS_LOG%" 2>nul
del "%SC_TASK_LOG%" 2>nul
call "%APPLY%" >nul 2>&1
if not "%errorlevel%"=="0" goto :fail_rerun
find /c "MANIFEST=" < "%SC_TASK_LOG%" > "%WORK%\count1.txt"
del "%SC_TASK_LOG%" 2>nul
call "%APPLY%" >nul 2>&1
set "RC5=%errorlevel%"
if not "%RC5%"=="0" goto :fail_rerun
find /c "MANIFEST=" < "%SC_TASK_LOG%" > "%WORK%\count2.txt"
fc "%WORK%\count1.txt" "%WORK%\count2.txt" >nul || goto :fail_rerun
findstr /c:"appx.ps1 register" "%SC_PS_LOG%" >nul && goto :fail_rerun
echo PASS [5] rerun: exit 0, same dispatch count, no bootstrap side effect
exit /b 0
:fail_rerun
echo FAIL [5] rerun: expected exit 0 with identical dispatches and no register
set /a FAILED+=1
exit /b 0

:check_check_drift
set "SYSAD_WINGET=%WORK%\no-winget.exe"
del "%SC_PS_LOG%" 2>nul
del "%SC_TASK_LOG%" 2>nul
del "%SC_REG_LOG%" 2>nul
del "%SC_CURL_LOG%" 2>nul
call "%APPLY%" check > "%WORK%\run6.txt" 2>&1
set "RC6=%errorlevel%"
if not "%RC6%"=="10" goto :fail_check_drift
if exist "%SC_TASK_LOG%" goto :fail_check_drift
if exist "%SC_REG_LOG%" goto :fail_check_drift
if exist "%SC_CURL_LOG%" goto :fail_check_drift
findstr /c:"msix-check.ps1" "%SC_PS_LOG%" >nul || goto :fail_check_drift
findstr /c:"appx.ps1 register" "%SC_PS_LOG%" >nul && goto :fail_check_drift
echo PASS [6] check: exit 10 drift, no mutations, msix self-check ran for real
exit /b 0
:fail_check_drift
echo FAIL [6] check: expected exit 10 with report-only path and real msix check
set /a FAILED+=1
exit /b 0

:check_check_refusal
set "SC_MSIX_BAD=1"
call "%APPLY%" check >nul 2>&1
set "RC7=%errorlevel%"
set "SC_MSIX_BAD="
if not "%RC7%"=="211" goto :fail_check_refusal
echo PASS [7] check refusal: unprovisioned package reports 211 in check mode
exit /b 0
:fail_check_refusal
set "SC_MSIX_BAD="
echo FAIL [7] check refusal: expected 211 from msix offender in check mode
set /a FAILED+=1
exit /b 0

:check_check_registry_clean
mkdir "%WORK%\mdir"
> "%WORK%\mdir\system-audit.yaml" echo items: []
> "%WORK%\mdir\registry.yaml" echo items:
>>"%WORK%\mdir\registry.yaml" echo   - { kind: registry-value, path: HKLM\SOFTWARE\Fixtures\Audit, name: Drill, value: declared }
set "SYSAD_WINGET=%FIXTURES%\winget-ok.cmd"
set "SYSAD_MANIFESTS_DIR=%WORK%\mdir"
set "SC_REG_STATE=%WORK%\reg-state.txt"
> "%SC_REG_STATE%" echo HKLM\SOFTWARE\Fixtures\Audit^|Drill=declared
del "%SC_REG_LOG%" 2>nul
call "%APPLY%" check > "%WORK%\run8.txt" 2>&1
set "RC8=%errorlevel%"
set "SYSAD_MANIFESTS_DIR="
set "SC_REG_STATE="
if not "%RC8%"=="0" goto :fail_check_registry_clean
findstr /c:"query" "%SC_REG_LOG%" >nul || goto :fail_check_registry_clean
echo PASS [8] check registry: converged value live-compared clean via reg seam
exit /b 0
:fail_check_registry_clean
set "SYSAD_MANIFESTS_DIR="
set "SC_REG_STATE="
echo FAIL [8] check registry: expected exit 0 with live reg query comparison
set /a FAILED+=1
exit /b 0
