@echo off
setlocal EnableDelayedExpansion

:: Auto elevation code taken from the following answer-
:: https://stackoverflow.com/a/28467343/14312937

:: net file to test privileges, 1>NUL redirects output, 2>NUL redirects errors
net FILE 1>NUL 2>NUL
if '%errorlevel%' == '0' ( goto start ) else ( goto getPrivileges ) 

:getPrivileges
if '%1'=='ELEV' ( goto start )

set "batchPath=%~f0"
set "batchArgs=ELEV"

:: Add quotes to the batch path, if needed
set "script=%0"
set script=%script:"=%
if '%0'=='!script!' ( goto PathQuotesDone )
    set "batchPath=""%batchPath%"""
:PathQuotesDone

:: Add quotes to the arguments, if needed
:ArgLoop
if '%1'=='' ( goto EndArgLoop ) else ( goto AddArg )
    :AddArg
    set "arg=%1"
    set arg=%arg:"=%
    if '%1'=='!arg!' ( goto NoQuotes )
        set "batchArgs=%batchArgs% "%1""
        goto QuotesDone
        :NoQuotes
        set "batchArgs=%batchArgs% %1"
    :QuotesDone
    shift
    goto ArgLoop
:EndArgLoop

:: Create and run the vb script to elevate the batch file
echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\OEgetPrivileges.vbs"
echo UAC.ShellExecute "cmd", "/c ""!batchPath! !batchArgs!""", "", "runas", 1 >> "%temp%\OEgetPrivileges.vbs"
"%temp%\OEgetPrivileges.vbs" 
exit /B

:start
:: Remove the elevation tag and set the correct working directory
if '%1'=='ELEV' ( shift /1 )
cd /d %~dp0

:: Main script here

@echo off
setlocal

title Update Hotspot Device Limit
echo Update Hotspot Device Limit
echo https://github.com/NaeemBolchhi/hotspot-limit
echo.

:: Define registry path and value name
set "REG_PATH=HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\icssvc\Settings"
set "VALUE_NAME=WifiMaxPeers"
set "VALUE_DATA="

echo.
echo This script will update the maximum number of devices for your mobile hotspot.
echo.

:GET_INPUT
echo Set a value greater than 0 but not greater than 128.
set /p "VALUE_DATA=Desired maximum number of devices: "

:: Input validation: check if input is a number
for /f "delims=0123456789" %%i in ("%VALUE_DATA%") do (
    echo.
    echo Invalid input. Please enter a numeric value.
    echo.
    goto :GET_INPUT
)

:: Check for value greater than 0
if %VALUE_DATA% leq 0 (
    echo.
    echo Please enter a value greater than 0.
    echo.
    goto :GET_INPUT
)

:: Check for values greater than 128
if %VALUE_DATA% gtr 128 (
    echo.
    echo Warning: Values above 128 might not be supported or stable.
    echo You entered: %VALUE_DATA%
    echo.
    :CONTINUE_PROMPT
    set /p "CHOICE=do you want to continue with this value (C) or enter a new one (N)? "
    if /i "%CHOICE%"=="N" (
        echo.
        goto :GET_INPUT
    ) else if /i "%CHOICE%"=="n" (
        echo.
        goto :GET_INPUT
    ) else if /i "%CHOICE%"=="C" (
        echo.
    ) else if /i "%CHOICE%"=="c" (
        echo.
    ) else (
        echo Invalid choice. Please enter 'C' to continue or 'N' to enter a new value.
        goto :CONTINUE_PROMPT
    )
)

echo.
echo Attempting to update registry value: %VALUE_NAME% to %VALUE_DATA%
echo Path: %REG_PATH%
echo.

:: Add or update the registry dword value
reg add "%REG_PATH%" /v "%VALUE_NAME%" /t REG_DWORD /d %VALUE_DATA% /f

if %errorlevel% equ 0 (
    echo Registry updated successfully.
    echo.
) else (
    echo Failed to update registry. Error code: %errorlevel%
    goto :END
)

echo Restarting 'icssvc' service...
echo.

:: Stop the service
net stop icssvc
if %errorlevel% neq 0 (
    echo Failed to stop 'icssvc' service. error code: %errorlevel%
    echo It might already be stopped or you lack the necessary permissions.
    echo Attempting to start it anyway.
)

:: Give a short pause
timeout /t 2 /nobreak >NUL

:: Start the service
net start icssvc
if %errorlevel% equ 0 (
    echo 'icssvc' service restarted successfully.
    echo Changes should now be applied.
) else (
    echo Failed to start 'icssvc' service. Error code: %errorlevel%
    echo You may need to manually start it or reboot your system.
)

:END
echo.
echo Script finished.
timeout 3