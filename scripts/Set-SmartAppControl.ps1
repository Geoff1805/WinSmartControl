param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("Evaluation", "Enforce", "Off", "Status")]
    [string]$Mode = "Evaluation",

    [Parameter(Mandatory = $false)]
    [switch]$TrainTools,

    [Parameter(Mandatory = $false)]
    [switch]$ConfigureDevTrust,

    [Parameter(Mandatory = $false)]
    [switch]$NonInteractive
)

# Configuration Encodage UTF-8 Standard (Antigravity)
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding           = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

$RegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy"
$ValueName = "VerifiedAndReputablePolicyState"

function Test-IsAdmin {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-SACStatus {
    $val = (Get-ItemProperty -Path $RegPath -Name $ValueName -ErrorAction SilentlyContinue).$ValueName
    switch ($val) {
        0 { return @{ Code = 0; Name = "Off (DÃ©sactivÃ©)"; Description = "Smart App Control est complÃ¨tement dÃ©sactivÃ©." } }
        1 { return @{ Code = 1; Name = "Enforce (ActivÃ©/Bloquant)"; Description = "Smart App Control bloque toute application non vÃ©rifiÃ©e ou sans rÃ©putation." } }
        2 { return @{ Code = 2; Name = "Evaluation (Apprentissage)"; Description = "Smart App Control est en mode apprentissage/Ã©valuation : il audite et apprend sans rien bloquer." } }
        default { return @{ Code = -1; Name = "Inconnu ($val)"; Description = "Ã‰tat non standard ou clÃ© absente." } }
    }
}

$current = Get-SACStatus
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   WinSmartControl - Gestionnaire Smart App Control       " -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "[+] Ã‰tat actuel de Smart App Control : $($current.Name)" -ForegroundColor Green
Write-Host "    $($current.Description)" -ForegroundColor Gray

if ($Mode -eq "Status") {
    exit 0
}

# Elevation check
if (-not (Test-IsAdmin)) {
    Write-Host "[!] Droits d'administrateur requis pour modifier Smart App Control." -ForegroundColor Yellow
    Write-Host "[*] Ã‰lÃ©vation automatique en cours via UAC..." -ForegroundColor Cyan
    
    $scriptPath = $MyInvocation.MyCommand.Path
    $argList = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" -Mode $Mode"
    if ($TrainTools) { $argList += " -TrainTools" }
    if ($ConfigureDevTrust) { $argList += " -ConfigureDevTrust" }
    
    $proc = Start-Process powershell.exe -ArgumentList $argList -Verb RunAs -PassThru -Wait
    exit $proc.ExitCode
}

# Apply target mode
$targetVal = switch ($Mode) {
    "Evaluation" { 2 }
    "Enforce"    { 1 }
    "Off"        { 0 }
}

Write-Host "`n[*] Application du mode : $Mode (Valeur registre = $targetVal)..." -ForegroundColor Cyan
try {
    if (-not (Test-Path $RegPath)) {
        New-Item -Path $RegPath -Force | Out-Null
    }
    Set-ItemProperty -Path $RegPath -Name $ValueName -Value $targetVal -Type DWord -Force
    Set-ItemProperty -Path $RegPath -Name "SAC_PreviousState" -Value $current.Code -Type DWord -Force
    Write-Host "[OK] Registre mis Ã  jour avec succÃ¨s : $ValueName = $targetVal" -ForegroundColor Green
} catch {
    Write-Host "[ERREUR] Ã‰chec de la mise Ã  jour du registre : $_" -ForegroundColor Red
    exit 1
}

# Refresh Code Integrity policy kernel-side
Write-Host "[*] RafraÃ®chissement du sous-systÃ¨me Code Integrity (citool.exe -r)..." -ForegroundColor Cyan
try {
    citool.exe -r 2>&1 | Out-Null
    Write-Host "[OK] Sous-systÃ¨me Code Integrity rafraÃ®chi." -ForegroundColor Green
} catch {
    Write-Host "[AVERTISSEMENT] citool.exe non disponible ou Ã©chec partiel : $_" -ForegroundColor Yellow
}

# Optional: Configure Developer Trust & Defender Exclusions
if ($ConfigureDevTrust) {
    Write-Host "`n[*] Configuration de la confiance dÃ©veloppeur (Exclusions Defender & Mode DÃ©veloppeur)..." -ForegroundColor Cyan
    $devPaths = @(
        "G:\Mon Drive\05_Dev",
        "C:\Users\geoff\.gemini",
        "C:\Users\geoff\.gemini\antigravity\bin"
    )
    foreach ($p in $devPaths) {
        if (Test-Path $p) {
            try {
                Add-MpPreference -ExclusionPath $p -ErrorAction SilentlyContinue
                Write-Host "  [OK] Exclusion Defender ajoutÃ©e : $p" -ForegroundColor Green
            } catch {
                Write-Host "  [!] Impossible d'ajouter l'exclusion pour $p : $_" -ForegroundColor Yellow
            }
        }
    }

    # Enable Developer Mode in Registry
    try {
        $devReg = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
        if (-not (Test-Path $devReg)) { New-Item -Path $devReg -Force | Out-Null }
        Set-ItemProperty -Path $devReg -Name "AllowDevelopmentWithoutDevLicense" -Value 1 -Type DWord -Force
        Write-Host "  [OK] Mode DÃ©veloppeur Windows activÃ© dans le registre." -ForegroundColor Green
    } catch {
        Write-Host "  [!] Impossible d'activer le mode dÃ©veloppeur : $_" -ForegroundColor Yellow
    }
}

# Training / Learning routine: exercise tools so ISG learns benign execution
if ($TrainTools) {
    Write-Host "`n[*] ExÃ©cution de la boucle d'apprentissage pour les outils dÃ©veloppeur..." -ForegroundColor Cyan
    $tools = @(
        @{ Name = "ripgrep"; Cmd = "rg --version" },
        @{ Name = "jq"; Cmd = "jq --version" },
        @{ Name = "git"; Cmd = "git --version" },
        @{ Name = "python"; Cmd = "py --version" },
        @{ Name = "adb"; Cmd = "adb version" },
        @{ Name = "biome"; Cmd = "biome --version" }
    )

    foreach ($t in $tools) {
        try {
            $out = Invoke-Expression $t.Cmd 2>&1
            Write-Host "  [Appris] $($t.Name) : $(($out | Select-Object -First 1))" -ForegroundColor Gray
        } catch {
            Write-Host "  [Info] $($t.Name) non exÃ©cutÃ© : $_" -ForegroundColor DarkGray
        }
    }
    Write-Host "[OK] Les outils ont Ã©tÃ© exÃ©cutÃ©s en mode Ã©valuation pour enregistrement tÃ©lÃ©mÃ©trique." -ForegroundColor Green
}

$updated = Get-SACStatus
Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "[SUCCÃˆS] Nouvel Ã©tat Smart App Control : $($updated.Name)" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan
