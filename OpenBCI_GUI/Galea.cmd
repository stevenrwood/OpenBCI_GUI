@if "%_echo%" == "" echo off
setlocal enabledelayedexpansion

rem call :connectToGateway
rem if ERRORLEVEL 1 (
rem     echo Unable to connect to Galea_Gateway network.
rem     exit /B 1
rem )

set _GALEAIP=
call :findgaleaip
if ERRORLEVEL 1 (
    echo No Galea headset found connected to Galea_Gateway network.  Is it powered on with a blue led
    echo indicating a successful connection to Galea_Gateway network?
    exit /B 1
)

if EXIST \\fileserver\user\stevew\BCIGame\v1.5\bcigame.exe (
    set bcigamePath=\\fileserver\user\stevew\BCIGame\v1.5
) else (
    set bcigamePath=%USERPROFILE%\bcigame
)
if EXIST .\OpenBCI_GUI.pde (
    set PRUN=%PROCESSING%\processing-java.exe --sketch=%USERPROFILE%\github\OpenBCI_GUI\OpenBCI_GUI --run
) else if EXIST \\fileserver\user\stevew\galea\OpenBCI_GUI\valve\OpenBCI_GUI\OpenBCI_GUI.exe (
    set PRUN=\\fileserver\user\stevew\galea\OpenBCI_GUI\valve\OpenBCI_GUI\OpenBCI_GUI.exe
) else (
    echo Unable to find OpenBCI_GUI.exe to run.
    exit /b 1
)
%PRUN% --cyton --daisy --wifi --ipAddress 192.168.4.1 --auxinput "%bcigamePath%\BciGame.exe --game FollowMe --logFolder $session --openBCIPort $bciport --StimulusDelay 1000 --FeedbackDelay 500 --TrialCount 10 --openBCIPort $bciport"
goto :eof

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
