@if "%_echo%" == "" echo off

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

set OpenBCICmd=%PRUN% --cyton --daisy --auxinput "%bcigamePath% --logFolder $session --openBCIPort $bciport --TrialCount 10 --game Simple --StimulusDelay 1000 --FeedbackDelay 500"
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
