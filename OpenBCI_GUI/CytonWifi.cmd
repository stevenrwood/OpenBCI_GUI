@if "%_echo%" == "" echo off
if EXIST \\fileserver\user\stevew\BCIGame\v1.5\bcigame.exe (
    set bcigamePath=\\fileserver\user\stevew\BCIGame\v1.5
) else (
    set bcigamePath=%USERPROFILE%\bcigame
)
%PROCESSING%\processing-java.exe --sketch=%USERPROFILE%\github\OpenBCI_GUI\OpenBCI_GUI --run --cyton --daisy --wifi --ipAddress 192.168.4.1 --auxinput "%bcigamePath%\BciGame.exe --game FollowMe --logFolder $session --openBCIPort $bciport --StimulusDelay 1000 --FeedbackDelay 500 --TrialCount 10 --openBCIPort $bciport"

