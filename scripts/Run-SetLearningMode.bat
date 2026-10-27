@echo off
chcp 65001 >nul
:: WinSmartControl - Bascule de Smart App Control en Mode Apprentissage (Evaluation)

echo ======================================================================
echo    WinSmartControl - Activation du Mode Apprentissage (Evaluation)
echo ======================================================================
echo.

:: Lancement du script PowerShell avec auto-élévation UAC si nécessaire
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Set-SmartAppControl.ps1" -Mode Evaluation -TrainTools

echo.
echo ======================================================================
echo  Operation terminee. Appuyez sur une touche pour quitter cette fenetre.
echo ======================================================================
pause >nul
