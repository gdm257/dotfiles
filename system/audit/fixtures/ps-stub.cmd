@echo off
rem powershell seam stub: logs invocations (raw + dequoted NORM line), fakes
rem msix-check / appx probe outcomes via SC_* env
set "PSARGS=%*"
>>"%SC_PS_LOG%" echo %PSARGS%
set "PSARGS=%PSARGS:"=%"
>>"%SC_PS_LOG%" echo NORM:%PSARGS%
if not "%PSARGS:msix-check.ps1=%"=="%PSARGS%" goto :msix
if not "%PSARGS:appx.ps1=%"=="%PSARGS%" goto :appx
exit /b 0
:msix
if not defined SC_MSIX_BAD exit /b 0
echo MSIX: Fake.BadApp
exit /b 1
:appx
if not "%PSARGS:probe=%"=="%PSARGS%" goto :probe
exit /b 0
:probe
if defined SC_PROBE_FAIL exit /b 1
exit /b 0
