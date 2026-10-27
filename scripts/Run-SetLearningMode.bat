@echo off
chcp 65001 >nul
:: WinSmartControl - Bascule de Smart App Control en Mode Apprentissage (Evaluation)
:: Ce script sollicite l'élévation UAC requise pour écrire dans HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy

echo ======================================================================
echo    WinSmartControl - Activation du Mode Apprentissage (Evaluation)
echo ======================================================================
echo.

:: Verification des droits administrateur
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Privilèges Administrateur requis.
    echo [*] Lancement de la demande d'élévation UAC Windows...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process cmd.exe -ArgumentList '/c ""%~f0""' -Verb RunAs"
    exit /b
)

:: Execution elevee du script PowerShell
echo [*] Exécution avec privilèges Administrateur...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Set-SmartAppControl.ps1" -Mode Evaluation -TrainTools -ConfigureDevTrust

echo.
echo ======================================================================
echo  Opération terminée. Appuyez sur une touche pour quitter cette fenêtre.
echo ======================================================================
pause >nul
