@if "%_echo%" == "" echo off
setlocal enabledelayedexpansion

call :connectToWifi
if ERRORLEVEL 1 (
    echo No Cyton WiFi headset found with a network name that begins with OpenBCI-
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

set OpenBCICmd=%PRUN% --cyton --daisy --wifi --ipAddress 192.168.4.1 --auxinput "%bcigamePath% --logFolder $session --openBCIPort $bciport --TrialCount 10 --game Simple --StimulusDelay 1000 --FeedbackDelay 500"
echo %OpenBCICmd%
%OpenBCICmd%
%_POPD%
goto :eof

:setpath
if EXIST %2 (
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

:connectToWifi
for /F "tokens=1-4" %%i in ('netsh wlan show networks') do (
    if "%%i" == "SSID" (
        if "%%l" NEQ "" (
            set _SSID=%%l
            if "!_SSID:OpenBCI-=!" NEQ "!_SSID!" (
                echo netsh wlan connect !_SSID!
                netsh wlan connect !_SSID!
                exit /B 0
            )
        )
    )
)
exit /B 1
