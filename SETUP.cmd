@echo off
setlocal
cd /d "%~dp0"
title PSTV Bluetooth Audio Bridge Setup

echo PSTV Bluetooth Audio Bridge
echo ===========================
echo.
echo Setup will detect your Bluetooth adapter, configure the appliance,
echo and guide you through pairing the PSTV as PLT Focus.
echo Your Wi-Fi adapter will not be disabled or reconfigured.
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install.ps1"
set "setup_exit=%errorlevel%"
echo.
if not "%setup_exit%"=="0" (
    echo Setup did not complete. Review the error above, then see docs\TROUBLESHOOTING.md.
) else (
    echo Setup finished successfully.
)
echo.
pause
exit /b %setup_exit%
