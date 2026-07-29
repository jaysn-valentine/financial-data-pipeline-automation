@echo off
setlocal
cd /d "%~dp0"

py -3 python\run_reporting_query.py
if errorlevel 1 exit /b %errorlevel%

py -3 python\send_daily_summary.py
exit /b %errorlevel%
