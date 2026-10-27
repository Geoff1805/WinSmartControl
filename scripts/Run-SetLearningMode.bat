@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Set-SmartAppControl.ps1" -Mode Evaluation -TrainTools
pause
