@if "%_echo%" == "" echo off

call :setpath bcigamePath \\fileserver\user\stevew\BCIGame\v1.5\bcigame.exe
if ERRORLEVEL 1 (
    call :setpath bcigamePath %USERPROFILE%\bcigame\bcigame.exe
    if ERRORLEVEL 1 (
        echo Unable to find bciGame.exe to run.
        exit /b 1
    )
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

echo %PRUN% --cyton --daisy --auxinput "%bcigamePath% --game FollowMe --logFolder $session --openBCIPort $bciport --StimulusDelay 1000 --FeedbackDelay 500 --TrialCount 10 --openBCIPort $bciport"
%PRUN% --cyton --daisy --auxinput "%bcigamePath% --game FollowMe --logFolder $session --openBCIPort $bciport --StimulusDelay 1000 --FeedbackDelay 500 --TrialCount 10 --openBCIPort $bciport"
goto :eof

:setpath
if EXIST %2 (
    set %1=%~f2
    exit /B 0
)
exit /B 1
