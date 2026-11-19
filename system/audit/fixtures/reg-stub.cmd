@echo off
rem reg seam stub: logs calls, answers query from SC_REG_STATE when defined
if /i "%~1"=="query" if defined SC_REG_STATE goto :serve
>>"%SC_REG_LOG%" echo %*
exit /b 0
:serve
>>"%SC_REG_LOG%" echo %*
for /f "usebackq tokens=1,2,* delims=|=" %%A in ("%SC_REG_STATE%") do (
    if "%%A"=="%~2" if "%%B"=="%~4" (
        echo %~2
        echo     %~4    REG_SZ    %%C
        exit /b 0
    )
)
exit /b 1
