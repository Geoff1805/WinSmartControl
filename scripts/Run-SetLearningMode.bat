@echo off
chcp 65001 >nul
:: WinSmartControl - Bascule de Smart App Control en Mode Apprentissage (Evaluation)

echo ======================================================================
echo    WinSmartControl - Activation du Mode Apprentissage (Evaluation)
echo ======================================================================
echo.

:: Application directe via le fichier registre officiel
echo [*] Application de la configuration Smart App Control dans le Registre...
reg.exe import "%~dp0..\Set-LearningMode.reg"

if %errorlevel% equ 0 (
    echo [SUCCES] Cle de registre mise a jour : Mode Evaluation (2).
    echo [*] Rafraichissement Code Integrity...
    citool.exe -r >nul 2>&1
    echo [OK] Code Integrity rafraichi.
) else (
    echo [!] Echec de l'import direct. Privileges Administrateur requis.
    echo [*] Tentative avec elevation UAC...
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Set-SmartAppControl.ps1" -Mode Evaluation -TrainTools
)

echo.
echo ======================================================================
echo  Operation terminee. Appuyez sur une touche pour quitter cette fenetre.
echo ======================================================================
pause >nul
