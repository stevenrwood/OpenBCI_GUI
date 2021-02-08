@if "%_echo%" == "" echo off
setlocal enabledelayedexpansion
set _CSVFILE=
call :findnewestfile %USERPROFILE%\Documents\OpenBCI_GUI\*.
if EXIST .\OpenBCI_GUI.pde (
    set PRUN=%PROCESSING%\processing-java.exe --sketch=%USERPROFILE%\github\OpenBCI_GUI\OpenBCI_GUI --run
) else if EXIST \\fileserver\user\stevew\galea\OpenBCI_GUI\valve\OpenBCI_GUI\OpenBCI_GUI.exe (
    set PRUN=\\fileserver\user\stevew\galea\OpenBCI_GUI\valve\OpenBCI_GUI\OpenBCI_GUI.exe
) else (
    echo Unable to find OpenBCI_GUI.exe to run.
    exit /b 1
)
echo %PRUN% --playback %_CSVFILE%
%PRUN% --playback %_CSVFILE%
goto :eof


:findnewestfile
for /F "tokens=1 delims=[] " %%i in ('dir /B /O-D %1') do (
    if /I "%%i" NEQ "Loading" (
        echo IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII=%%i %~dp1  %~dp1%%i\
        for /F "tokens=1" %%o in ('dir /B %~dp1%%i\OpenBCI*.csv') do (
            if /I "%%o" NEQ "Loading" (
                echo CSVFile=%%o
                set _CSVFILE=%~dp1%%i\%%o
                goto :eof
            )
        )
    )
)
echo Unable to find recent playback file under %1
exit /B 1

