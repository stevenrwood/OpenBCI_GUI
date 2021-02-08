@if "%_echo%" == "" echo off
setlocal enabledelayedexpansion
call :connectToWifi
pause
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

:connectToWifi
set _SSID=
for /F "tokens=1-4" %%i in ('netsh wlan show networks') do (
    if "%%i" == "SSID" (
        if "%%l" NEQ "" (
            set _SSID=%%l
            echo if "!_SSID:OpenBCI-=!" NEQ "!_SSID!"
            if "!_SSID:OpenBCI-=!" NEQ "!_SSID!" (
                goto :connectToWifi1
            )
        )
    )
)
:connectToWifi1
echo _SSID=%_SSID%
if DEFINED _SSID (
    echo netsh wlan connect %_SSID%
    netsh wlan connect %_SSID%
) else (
    echo No Cyton WiFi headset found with a network name that begins with OpenBCI-
)
goto :eof
