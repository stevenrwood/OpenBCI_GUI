@if "%_echo%" == "" echo off
setlocal enabledelayedexpansion
call :findnewestfile %USERPROFILE%\Documents\OpenBCI_GUI\*.
if ERRORLEVEL 1 (
    echo Unable to find recent playback file under %USERPROFILE%\Documents\OpenBCI_GUI
    exit /B 1
)

call :setpath PRUN .\OpenBCI_GUI.pde
if ERRORLEVEL 1 (
    call :setpath PRUN \\fileserver\user\stevew\galea\OpenBCI_GUI\valve\OpenBCI_GUI\OpenBCI_GUI.exe
    if ERRORLEVEL 1 (
        call :setpath PRUN %USERPROFILE%\OpenBCI_GUI\OpenBCI_GUI.exe
        if ERRORLEVEL 1 (
            echo Unable to find OpenBCI_GUI.exe to run.
            exit /b 1
        )
    )
) else (
    set PRUN=%PROCESSING%\processing-java.exe --sketch=%USERPROFILE%\github\OpenBCI_GUI\OpenBCI_GUI --run
)

echo %PRUN% --playback %_CSVFILE%
%PRUN% --playback %_CSVFILE%
goto :eof


:findnewestfile
for /F "tokens=1 delims=[] " %%i in ('dir /B /O-D %1') do (
    if /I "%%i" NEQ "Loading" (
        for /F "tokens=1" %%o in ('dir /B %~dp1%%i\OpenBCI*.csv 2^>nul') do (
            if /I "%%o" NEQ "Loading" (
                set _CSVFILE=%~dp1%%i\%%o
                exit /B 0
            )
        )
    )
)
exit /B 1

:setpath
if EXIST %2 (
    set %1=%~f2
    cd /D %~dp2
    exit /B 0
)
exit /B 1
