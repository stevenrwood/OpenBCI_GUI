@if "%_echo%" == "" echo off
setlocal enabledelayedexpansion

call :connectToGateway
if ERRORLEVEL 1 (
    echo Unable to connect to Galea_Gateway network.
    exit /B 1
)

set _GALEAIP=
call :findgaleaip
if ERRORLEVEL 1 (
    echo No Galea headset found connected to Galea_Gateway network.  Is it powered on with a blue led
    echo indicating a successful connection to Galea_Gateway network?
    exit /B 1
)

call :setpath bcigamePath \\fileserver\user\stevew\BCIGame\v1.5\bcigame.exe 0
if ERRORLEVEL 1 (
    call :setpath bcigamePath %USERPROFILE%\bcigame\bcigame.exe
    if ERRORLEVEL 1 (
        echo Unable to find bciGame.exe to run.
        exit /b 1
    )
)

set _POPD=
call :setpath PRUN .\OpenBCI_GUI.pde 0
if ERRORLEVEL 1 (
    call :setpath PRUN \\fileserver\user\stevew\galea\OpenBCI_GUI\valve\OpenBCI_GUI\OpenBCI_GUI.exe 1
    if ERRORLEVEL 1 (
        call :setpath PRUN %USERPROFILE%\OpenBCI_GUI\OpenBCI_GUI.exe 2
        if ERRORLEVEL 1 (
            echo Unable to find OpenBCI_GUI.exe to run.
            exit /b 1
        )
    )
) else (
    set PRUN=%PROCESSING%\processing-java.exe --sketch=%USERPROFILE%\github\OpenBCI_GUI\OpenBCI_GUI --run
)

echo %PRUN% --galea --ipAddress %_GALEAIP% --auxinput "%bcigamePath% --game FollowMe --logFolder $session --openBCIPort $bciport --StimulusDelay 1000 --FeedbackDelay 500 --TrialCount 10 --openBCIPort $bciport"
%PRUN% --galea --ipAddress %_GALEAIP% --auxinput "%bcigamePath% --game FollowMe --logFolder $session --openBCIPort $bciport --StimulusDelay 1000 --FeedbackDelay 500 --TrialCount 10 --openBCIPort $bciport"
%_POPD%
goto :eof

:setpath
if EXIST %2 (
    echo set %1=%~f2
    set %1=%~f2
    if "%3" == "1" (
        pushd %~dp2
        set _POPD=popd
    ) else if "%3" == "2" (
        cd /D %~dp2
    )
    exit /B 0
)
exit /B 1

:connectToGateway
for /F "tokens=1-4" %%i in ('netsh wlan show networks') do (
    if "%%i" == "SSID" (
        if "%%l" == "Galea_Gateway" (
            echo netsh wlan connect %%l
            netsh wlan connect %%l GaleaOBCI^@
            exit /B 0
        )
    )
)
exit /B 1

:findgaleaip
for /F "tokens=1-3" %%i in ('arp -a') do (
    if /I "%%j" == "3c-18-a0-a0-1b-66" (
        set _GALEAIP=%%i
        exit /B 0
    )
)
exit /B 1
