@echo off
setlocal EnableExtensions

rem Audit stage converge: winget bootstrap, machine-scope baseline installs,
rem HKLM settings, Default profile preset, final MSIX self-check (KB2769827).
rem Seams: SYSAD_WINGET SYSAD_POWERSHELL SYSAD_CURL SYSAD_MSIXURL SYSAD_TASK
rem        SYSAD_REG SYSAD_NTUSER SYSAD_DPDIR SYSAD_DPDEST; `check` arg or
rem        CHECK=1 routes mutations report-only.
rem Exit codes: 211 unprovisioned per-user MSIX, 212 winget bootstrap,
rem             213 manifest step, 214 default profile step, check drift 10.

set "PAYLOAD=%~dp0"
set "ROOT=%PAYLOAD%..\.."

set "PS=powershell -NoProfile -ExecutionPolicy Bypass"
if defined SYSAD_POWERSHELL set "PS=%SYSAD_POWERSHELL%"
set "TASK=task --taskfile taskfile.d\manifest.yaml --dir . dispatch"
if defined SYSAD_TASK set "TASK=%SYSAD_TASK%"
set "REG=reg.exe"
if defined SYSAD_REG set "REG=%SYSAD_REG%"
set "CURL=curl.exe -L"
if defined SYSAD_CURL set "CURL=%SYSAD_CURL%"
set "MSIXURL=https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
if defined SYSAD_MSIXURL set "MSIXURL=%SYSAD_MSIXURL%"
set "NTUSER=C:\Users\Default\NTUSER.DAT"
if defined SYSAD_NTUSER set "NTUSER=%SYSAD_NTUSER%"
set "DPSRC=%PAYLOAD%default-profile"
if defined SYSAD_DPDIR set "DPSRC=%SYSAD_DPDIR%"
set "DPDEST=C:\Users\Default"
set "MDIR=%ROOT%\manifests"
if defined SYSAD_MANIFESTS_DIR set "MDIR=%SYSAD_MANIFESTS_DIR%"

set "MODE=apply"
if "%~1"=="check" set "MODE=check"
if "%CHECK%"=="1" set "MODE=check"

set "TS=%DATE%-%TIME%"
set "TS=%TS:/=-%"
set "TS=%TS::=-%"
set "TS=%TS:.=-%"
set "TS=%TS: =-%"
set "LOGDIR=%TEMP%\system"
if not exist "%LOGDIR%" mkdir "%LOGDIR%"
set "LOG=%LOGDIR%\audit-%TS%.log"
set "OUT=%TEMP%\sysad-out.txt"

set /a RC=0
set /a DRIFT=0

call :log "audit: mode %MODE%, log %LOG%"

pushd "%ROOT%"
call :step_bootstrap
call :step_installs
call :step_registry
call :step_profile
call :step_msix
popd

if %RC% NEQ 0 exit /b %RC%
if "%MODE%"=="check" if %DRIFT% EQU 1 goto :finish_drift
call :log "OK: audit %MODE% done"
exit /b %RC%

:finish_drift
call :log "CHECK: drift, rerun without check to converge"
exit /b 10

:step_bootstrap
set "WG="
if defined SYSAD_WINGET goto :winget_seam
where winget.exe >nul 2>nul && set "WG=winget.exe"
goto :winget_check
:winget_seam
if exist "%SYSAD_WINGET%" set "WG=%SYSAD_WINGET%"
:winget_check
if defined WG goto :winget_ready
call :log "bootstrap: winget unavailable, registering App Installer"
if "%MODE%"=="check" goto :bootstrap_check
call %PS% -File "%PAYLOAD%appx.ps1" probe >nul 2>nul
if errorlevel 1 goto :bootstrap_bundle
call %PS% -File "%PAYLOAD%appx.ps1" register > "%OUT%" 2>&1
if errorlevel 1 goto :bootstrap_fail
call :flush
call :log "OK: App Installer registered"
goto :winget_done
:bootstrap_bundle
call :log "bootstrap: App Installer missing, msixbundle fallback"
set "MSX=%TEMP%\Microsoft.DesktopAppInstaller.msixbundle"
del "%MSX%" 2>nul
call %CURL% -o "%MSX%" "%MSIXURL%" >nul 2>nul
if not exist "%MSX%" goto :bootstrap_fail
call %PS% -File "%PAYLOAD%appx.ps1" install "%MSX%" > "%OUT%" 2>&1
if errorlevel 1 goto :bootstrap_fail
call :flush
call %PS% -File "%PAYLOAD%appx.ps1" register > "%OUT%" 2>&1
if errorlevel 1 goto :bootstrap_fail
call :flush
call :log "OK: App Installer deployed from msixbundle"
goto :winget_done
:bootstrap_check
set /a DRIFT=1
call :log "CHECK: would bootstrap winget (drift)"
goto :winget_done
:bootstrap_fail
call :flush
call :log "FAIL: winget bootstrap"
if %RC% EQU 0 set /a RC=212
goto :winget_done
:winget_ready
call :log "OK: winget available (%WG%)"
:winget_done
exit /b 0

:step_installs
if "%MODE%"=="check" goto :installs_check
call %TASK% MANIFEST=manifests/system-audit.yaml CALLS=winget-app=winget:install > "%OUT%" 2>&1
if not "%errorlevel%"=="0" goto :installs_fail
call :flush
call :log "OK: machine-scope baseline installed"
exit /b 0
:installs_check
findstr /c:"kind:" "%MDIR%\system-audit.yaml" >nul 2>nul
if errorlevel 1 exit /b 0
set /a DRIFT=1
call :log "CHECK: would install manifests/system-audit.yaml (drift)"
exit /b 0
:installs_fail
call :flush
call :log "FAIL: machine-scope baseline install"
if %RC% EQU 0 set /a RC=213
exit /b 0

:step_registry
if "%MODE%"=="check" goto :registry_check
call %TASK% MANIFEST=manifests/registry.yaml CALLS=registry-value=registry:set > "%OUT%" 2>&1
if not "%errorlevel%"=="0" goto :registry_fail
call :flush
call :log "OK: HKLM settings applied"
exit /b 0
:registry_check
findstr /c:"registry-value" "%MDIR%\registry.yaml" >nul 2>nul || exit /b 0
rem shortcut: flow-map 解析假定字段值不含逗号，REG_SZ/REG_DWORD 之外类型保守报漂移
for /f "delims=" %%L in ('findstr /c:"registry-value" "%MDIR%\registry.yaml"') do call :reg_item %%L
if not defined REGDRIFT exit /b 0
set /a DRIFT=1
call :log "CHECK: registry values drifted (drift)"
exit /b 0

:reg_item
set "RPATH=" & set "RNAME=" & set "RVAL=" & set "RTYPE=REG_SZ"
:reg_kv
if "%~1"=="" goto :reg_query
if /i "%~1"=="path:" call :reg_set RPATH %~2
if /i "%~1"=="name:" call :reg_set RNAME %~2
if /i "%~1"=="type:" call :reg_set RTYPE %~2
if /i "%~1"=="value:" call :reg_set RVAL %~2
shift & shift
goto :reg_kv

:reg_set
set "%~1=%~2"
exit /b 0
exit /b 0

:reg_query
if not defined RPATH goto :reg_drift
if not defined RNAME goto :reg_drift
if /i not "%RTYPE%"=="REG_SZ" if /i not "%RTYPE%"=="REG_DWORD" goto :reg_drift
set "GOT="
for /f "tokens=1,2,*" %%X in ('call "%REG%" query "%RPATH%" /v "%RNAME%" 2^>nul') do if /i "%%X"=="%RNAME%" set "GOT=%%Y %%Z"
if not defined GOT goto :reg_drift
set "WANT=%RVAL%"
if /i "%RTYPE%"=="REG_DWORD" call :reg_dword
if /i not "%GOT%"=="%RTYPE% %WANT%" goto :reg_drift
exit /b 0

:reg_dword
set "DEC="
set /a DEC=(%RVAL%) >nul 2>nul
if not defined DEC goto :reg_drift
cmd /c exit /b %DEC%
set "WANT=0x%=ExitCode%"
exit /b 0

:reg_drift
set "REGDRIFT=1"
exit /b 0
:registry_fail
call :flush
call :log "FAIL: HKLM settings"
if %RC% EQU 0 set /a RC=213
exit /b 0

:step_profile
if exist "%NTUSER%" goto :dp_hive
call :log "default profile: NTUSER.DAT absent, skipped"
goto :dp_files
:dp_hive
if "%MODE%"=="check" goto :dp_hive_check
call "%REG%" load HKLM\TMP_SYSAD_DP "%NTUSER%" >nul 2>nul
if errorlevel 1 goto :dp_hive_reuse
call :log "OK: default profile hive loaded"
goto :dp_hive_apply
:dp_hive_reuse
call "%REG%" query HKLM\TMP_SYSAD_DP >nul 2>nul
if errorlevel 1 goto :dp_fail
call :log "OK: default profile hive already loaded, reusing"
:dp_hive_apply
call %TASK% MANIFEST=manifests/system-default-profile.yaml CALLS=registry-value=registry:set > "%OUT%" 2>&1
if not "%errorlevel%"=="0" goto :dp_fail
call :flush
call "%REG%" unload HKLM\TMP_SYSAD_DP >nul 2>nul
if errorlevel 1 goto :dp_fail
call :log "OK: default profile hive applied and unloaded"
goto :dp_files
:dp_hive_check
findstr /c:"kind:" "%MDIR%\system-default-profile.yaml" >nul 2>nul
if errorlevel 1 goto :dp_files
set /a DRIFT=1
call :log "CHECK: would apply manifests/system-default-profile.yaml to default hive (drift)"
:dp_files
if not exist "%DPSRC%\*" goto :dp_done
if "%MODE%"=="check" goto :dp_files_check
xcopy /e /i /y /d "%DPSRC%\*" "%DPDEST%\" > "%OUT%" 2>&1
if not "%errorlevel%"=="0" goto :dp_fail
call :flush
call :log "OK: default profile file seeds copied"
goto :dp_done
:dp_files_check
set /a DRIFT=1
call :log "CHECK: would seed default profile files (drift)"
:dp_done
exit /b 0
:dp_fail
call :flush
call :log "FAIL: default profile step"
if %RC% EQU 0 set /a RC=214
exit /b 0

:step_msix
call %PS% -File "%PAYLOAD%msix-check.ps1" > "%OUT%" 2>&1
if errorlevel 1 goto :msix_fail
call :flush
call :log "OK: no unprovisioned per-user MSIX packages"
exit /b 0
:msix_fail
call :flush
call :log "FAIL: unprovisioned per-user MSIX package(s) present (KB2769827)"
if %RC% EQU 0 set /a RC=211
exit /b 0

:flush
type "%OUT%"
>>"%LOG%" type "%OUT%"
del "%OUT%" 2>nul
exit /b 0

:log
echo(%~1
>>"%LOG%" echo(%~1
exit /b 0
