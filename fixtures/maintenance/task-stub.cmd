@echo off
rem task stub: record invoked task name, always succeed
>> "%TASK_STUB_LOG%" echo %~1
exit /b 0
