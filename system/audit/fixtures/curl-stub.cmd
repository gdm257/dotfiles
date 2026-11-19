@echo off
rem curl seam stub: logs the url, creates the -o target so the fallback proceeds
>>"%SC_CURL_LOG%" echo %*
type nul > "%~2"
exit /b 0
