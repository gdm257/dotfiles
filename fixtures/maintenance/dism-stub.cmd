@echo off
rem dism stub: /get-featureinfo reports Disabled for *-off features, Enabled otherwise
set "F=%~3"
set "F=%F:featurename:=%"
echo Feature Info:
if /i "%F:~-4%"=="-off" (echo State : Disabled) else echo State : Enabled
exit /b 0
