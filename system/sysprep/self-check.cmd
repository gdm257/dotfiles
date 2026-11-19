@echo off
setlocal EnableExtensions

rem Self-check for seal.cmd, capture.cmd and check.cmd. Stub seams only,
rem no real system state is touched.

set "ROOT=%~dp0"
set "WORK=%TEMP%\sysp-selfcheck"
set "STAGE=%WORK%\system\sysprep"
set "ROOTS=%WORK%\roots"
set /a FAILED=0

if exist "%WORK%" rmdir /s /q "%WORK%"
mkdir "%STAGE%"
mkdir "%ROOTS%\D\Windows"
mkdir "%ROOTS%\E"
mkdir "%ROOTS%\F"
copy /y "%ROOT%seal.cmd" "%STAGE%\" >nul
copy /y "%ROOT%capture.cmd" "%STAGE%\" >nul
copy /y "%ROOT%check.cmd" "%STAGE%\" >nul
copy /y "%ROOT%..\unattend.xml" "%WORK%\system\" >nul

set "COMBLOG=%WORK%\stub-combined.log"
set "FLAG=%WORK%\netoff.flag"
set "DISMLOG=%WORK%\dism-stub.log"
set "NETOFF=%WORK%\netoff-stub.cmd"
set "SYSPREPSTUB=%WORK%\sysprep-stub.cmd"
set "DISMSTUB=%WORK%\dism-stub.cmd"
set "MARKER=%WORK%\sealed.marker"

(
echo @echo off
echo ^>^>"%%SYSP_COMBLOG%%" echo NETOFF
echo type nul ^> "%%SYSP_FLAG%%"
echo exit /b 0
) > "%NETOFF%"
(
echo @echo off
echo ^>^>"%%SYSP_COMBLOG%%" echo SYSPREP %%*
echo if exist "%%SYSP_FLAG%%" ^(
echo ^>^>"%%SYSP_COMBLOG%%" echo PRE-NETOFF-OK
echo ^) else ^(
echo ^>^>"%%SYSP_COMBLOG%%" echo PRE-NETOFF-BAD
echo ^)
echo if defined SYSPRC exit /b %%SYSPRC%%
echo exit /b 0
) > "%SYSPREPSTUB%"
(
echo @echo off
echo ^>^>"%%SYSP_DISMLOG%%" echo DISM %%*
echo if defined DISMRC exit /b %%DISMRC%%
echo exit /b 0
) > "%DISMSTUB%"

set "VOLA=%WORK%\vol-a.txt"
set "VOLB=%WORK%\vol-b.txt"
set "VOLC=%WORK%\vol-c.txt"
(
echo X: 99999 boot
echo N: 88888 net
echo %ROOTS%\D 100 fixed
echo %ROOTS%\E 400 fixed
echo %ROOTS%\F 150 fixed
) > "%VOLA%"
(
echo %ROOTS%\F 150 fixed
echo X: 99999 boot
echo %ROOTS%\E 400 fixed
echo %ROOTS%\D 100 fixed
echo N: 88888 net
) > "%VOLB%"
(
echo X: 99999 boot
echo N: 88888 net
echo %ROOTS%\D 100 fixed
) > "%VOLC%"

call :check_seal_refuse
call :check_seal_happy
call :check_seal_args
call :check_seal_marker
call :check_seal_fail
call :seam_setup
call :check_cap_refuse_unsealed
call :check_cap_refuse_wim
call :check_cap_pick_a
call :check_cap_pick_b
call :check_cap_name
call :check_cap_no_part
call :seam_teardown
call :check_unattend
call :check_check_ready
call :check_check_sealed

echo.
echo self-check: %FAILED% failed assertion(s)
if exist "%WORK%" rmdir /s /q "%WORK%"
exit /b %FAILED%

:seam_setup
set "SYSP_SYSPREP=%SYSPREPSTUB%"
set "SYSP_NETOFF=%NETOFF%"
set "SYSP_MARKER=%MARKER%"
set "SYSP_COMBLOG=%COMBLOG%"
set "SYSP_FLAG=%FLAG%"
set "SYSP_DISM=%DISMSTUB%"
set "SYSP_DISMLOG=%DISMLOG%"
set "SYSP_BOOT=X:"
set "SYSP_DATE=20260401"
set "SYSP_BUILD=26100"
exit /b 0

:seam_teardown
set "SYSP_SYSPREP="
set "SYSP_NETOFF="
set "SYSP_MARKER="
set "SYSP_COMBLOG="
set "SYSP_FLAG="
set "SYSP_DISM="
set "SYSP_DISMLOG="
set "SYSP_BOOT="
set "SYSP_DATE="
set "SYSP_BUILD="
exit /b 0

:check_seal_refuse
call :seam_setup
echo sealed > "%MARKER%"
del "%COMBLOG%" 2>nul
del "%FLAG%" 2>nul
call "%STAGE%\seal.cmd" >nul
if not "%errorlevel%"=="241" goto :fail_seal_refuse
if exist "%COMBLOG%" goto :fail_seal_refuse
echo PASS [1] seal refuse: exit 241 on sealed marker, stubs untouched
exit /b 0
:fail_seal_refuse
echo FAIL [1] seal refuse: expected exit 241 without stub invocation
set /a FAILED+=1
exit /b 0

:check_seal_happy
del "%MARKER%" 2>nul
del "%COMBLOG%" 2>nul
del "%FLAG%" 2>nul
set "SYSPRC="
call "%STAGE%\seal.cmd" >nul
if not "%errorlevel%"=="0" goto :fail_seal_happy
if not exist "%FLAG%" goto :fail_seal_happy
findstr /c:"PRE-NETOFF-OK" "%COMBLOG%" >nul || goto :fail_seal_happy
echo PASS [2] seal happy: exit 0, network disabled before sysprep
exit /b 0
:fail_seal_happy
echo FAIL [2] seal happy: expected exit 0 with network off before sysprep
set /a FAILED+=1
exit /b 0

:check_seal_args
findstr /c:"SYSPREP /generalize /oobe /unattend:%WORK%\system\unattend.xml /shutdown" "%COMBLOG%" >nul || goto :fail_seal_args
echo PASS [3] seal args: exact sysprep command line
exit /b 0
:fail_seal_args
echo FAIL [3] seal args: expected /generalize /oobe /unattend system\unattend.xml /shutdown
set /a FAILED+=1
exit /b 0

:check_seal_marker
if not exist "%MARKER%" goto :fail_seal_marker
echo PASS [4] seal marker: sealed marker written
exit /b 0
:fail_seal_marker
echo FAIL [4] seal marker: expected sealed marker present
set /a FAILED+=1
exit /b 0

:check_seal_fail
del "%MARKER%" 2>nul
del "%COMBLOG%" 2>nul
set "SYSPRC=3"
call "%STAGE%\seal.cmd" >nul
set "RC=%errorlevel%"
set "SYSPRC="
if not "%RC%"=="245" goto :fail_seal_fail
if exist "%MARKER%" goto :fail_seal_fail
echo PASS [5] seal fail: exit 245 on sysprep failure, no marker
exit /b 0
:fail_seal_fail
set "SYSPRC="
echo FAIL [5] seal fail: expected exit 245 without marker
set /a FAILED+=1
exit /b 0

:check_cap_refuse_unsealed
call :seam_setup
del "%DISMLOG%" 2>nul
call "%STAGE%\capture.cmd" "%ROOTS%\D" >nul
if not "%errorlevel%"=="242" goto :fail_cap_unsealed
if exist "%DISMLOG%" goto :fail_cap_unsealed
echo PASS [6] capture refuse: exit 242 without sealed marker, dism untouched
exit /b 0
:fail_cap_unsealed
echo FAIL [6] capture refuse: expected exit 242 without dism invocation
set /a FAILED+=1
exit /b 0

:check_cap_refuse_wim
echo sealed > "%MARKER%"
set "SYSP_VOLUMES=%VOLA%"
echo wim > "%ROOTS%\E\install-20200101-12345.wim"
del "%DISMLOG%" 2>nul
call "%STAGE%\capture.cmd" "%ROOTS%\D" >nul
if not "%errorlevel%"=="243" goto :fail_cap_wim
if exist "%DISMLOG%" goto :fail_cap_wim
del "%ROOTS%\E\install-20200101-12345.wim"
set "SYSP_VOLUMES="
echo PASS [7] capture refuse: exit 243 on existing wim, dism untouched
exit /b 0
:fail_cap_wim
del "%ROOTS%\E\install-20200101-12345.wim" 2>nul
set "SYSP_VOLUMES="
echo FAIL [7] capture refuse: expected exit 243 without dism invocation
set /a FAILED+=1
exit /b 0

:cap_run
del "%DISMLOG%" 2>nul
if exist "%STAGE%\capture-*.log" del "%STAGE%\capture-*.log" >nul
set "SYSP_VOLUMES=%~1"
call "%STAGE%\capture.cmd" "%ROOTS%\D" >nul
set "RC=%errorlevel%"
set "SYSP_VOLUMES="
exit /b 0

:check_cap_pick_a
call :cap_run "%VOLA%"
if not "%RC%"=="0" goto :fail_cap_pick_a
findstr /c:"/Capture-Image" "%DISMLOG%" >nul || goto :fail_cap_pick_a
findstr /c:"%ROOTS%\E" "%DISMLOG%" >nul || goto :fail_cap_pick_a
findstr /c:"%ROOTS%\D" "%DISMLOG%" >nul || goto :fail_cap_pick_a
echo PASS [8] capture pick A: largest eligible partition chosen over boot/net/target
exit /b 0
:fail_cap_pick_a
echo FAIL [8] capture pick A: expected %ROOTS%\E captured from %ROOTS%\D
set /a FAILED+=1
exit /b 0

:check_cap_pick_b
call :cap_run "%VOLB%"
if not "%RC%"=="0" goto :fail_cap_pick_b
findstr /c:"%ROOTS%\E\install-" "%DISMLOG%" >nul || goto :fail_cap_pick_b
echo PASS [9] capture pick B: same choice under shuffled volume order
exit /b 0
:fail_cap_pick_b
echo FAIL [9] capture pick B: expected %ROOTS%\E chosen regardless of ordering
set /a FAILED+=1
exit /b 0

:check_cap_name
findstr /c:"%ROOTS%\E\install-20260401-26100.wim" "%DISMLOG%" >nul || goto :fail_cap_name
echo PASS [10] capture name: wim named with date and build
exit /b 0
:fail_cap_name
echo FAIL [10] capture name: expected install-20260401-26100.wim in dism args
set /a FAILED+=1
exit /b 0

:check_cap_no_part
del "%DISMLOG%" 2>nul
set "SYSP_VOLUMES=%VOLC%"
call "%STAGE%\capture.cmd" "%ROOTS%\D" >nul
set "RC=%errorlevel%"
set "SYSP_VOLUMES="
if not "%RC%"=="244" goto :fail_cap_no_part
if exist "%DISMLOG%" goto :fail_cap_no_part
echo PASS [11] capture no partition: exit 244 when only boot/net/target eligible
exit /b 0
:fail_cap_no_part
echo FAIL [11] capture no partition: expected exit 244 without dism invocation
set /a FAILED+=1
exit /b 0

:check_unattend
powershell -NoProfile -Command "try { [xml](Get-Content -Raw '%ROOT%..\unattend.xml') | Out-Null; exit 0 } catch { exit 1 }"
if errorlevel 1 goto :fail_unattend
findstr /c:"<SkipRearm>1</SkipRearm>" "%ROOT%..\unattend.xml" >nul || goto :fail_unattend
echo PASS [12] unattend: well-formed XML with SkipRearm in generalize pass
exit /b 0
:fail_unattend
echo FAIL [12] unattend: expected well-formed XML with SkipRearm
set /a FAILED+=1
exit /b 0

:check_check_ready
set "SYSP_MARKER=%WORK%\check-marker"
call "%STAGE%\check.cmd" >nul
set "RC=%errorlevel%"
set "SYSP_MARKER="
if not "%RC%"=="0" goto :fail_check_ready
echo PASS [13] check ready: exit 0 when not sealed
exit /b 0
:fail_check_ready
set "SYSP_MARKER="
echo FAIL [13] check ready: expected exit 0
set /a FAILED+=1
exit /b 0

:check_check_sealed
echo sealed > "%WORK%\check-marker"
set "SYSP_MARKER=%WORK%\check-marker"
call "%STAGE%\check.cmd" >nul
set "RC=%errorlevel%"
set "SYSP_MARKER="
if not "%RC%"=="10" goto :fail_check_sealed
echo PASS [14] check sealed: exit 10 when sealed, capture pending
exit /b 0
:fail_check_sealed
set "SYSP_MARKER="
echo FAIL [14] check sealed: expected exit 10
set /a FAILED+=1
exit /b 0
