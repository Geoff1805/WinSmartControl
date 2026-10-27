param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("Evaluation", "Enforce", "Off", "Status")]
    [string]$Mode = "Evaluation",

    [Parameter(Mandatory = $false)]
    [switch]$TrainTools,

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
        0 { return @{ Code = 0; Name = "Off (Désactivé)"; Description = "Smart App Control est complètement désactivé." } }
        1 { return @{ Code = 1; Name = "Enforce (Activé/Bloquant)"; Description = "Smart App Control bloque toute application non vérifiée ou sans réputation." } }
        2 { return @{ Code = 2; Name = "Evaluation (Apprentissage)"; Description = "Smart App Control est en mode apprentissage/évaluation : il audite et apprend sans rien bloquer." } }
        default { return @{ Code = -1; Name = "Inconnu ($val)"; Description = "État non standard ou clé absente." } }
    }
}

$current = Get-SACStatus
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   WinSmartControl - Gestionnaire Smart App Control       " -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "[+] État actuel de Smart App Control : $($current.Name)" -ForegroundColor Green
Write-Host "    $($current.Description)" -ForegroundColor Gray

if ($Mode -eq "Status") {
    exit 0
}

# Elevation check
if (-not (Test-IsAdmin)) {
    Write-Host "[!] Droits d'administrateur requis pour modifier Smart App Control." -ForegroundColor Yellow
    Write-Host "[*] Élévation automatique en cours via UAC..." -ForegroundColor Cyan
    
    $scriptPath = $MyInvocation.MyCommand.Path
    $argList = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" -Mode $Mode"
    if ($TrainTools) { $argList += " -TrainTools" }
    
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
    Write-Host "[OK] Registre mis à jour avec succès : $ValueName = $targetVal" -ForegroundColor Green
} catch {
    Write-Host "[ERREUR] Échec de la mise à jour du registre : $_" -ForegroundColor Red
    exit 1
}

# Refresh Code Integrity policy kernel-side
Write-Host "[*] Rafraîchissement du sous-système Code Integrity (citool.exe -r)..." -ForegroundColor Cyan
try {
    citool.exe -r 2>&1 | Out-Null
    Write-Host "[OK] Sous-système Code Integrity rafraîchi." -ForegroundColor Green
} catch {
    Write-Host "[AVERTISSEMENT] citool.exe non disponible ou échec partiel : $_" -ForegroundColor Yellow
}

# Training / Learning routine: exercise tools so ISG learns benign execution
if ($TrainTools) {
    Write-Host "`n[*] Exécution de la boucle d'apprentissage pour les outils développeur..." -ForegroundColor Cyan
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
            Write-Host "  [Info] $($t.Name) non exécuté : $_" -ForegroundColor DarkGray
        }
    }
    Write-Host "[OK] Les outils ont été exécutés en mode évaluation pour enregistrement télémétrique." -ForegroundColor Green
}

$updated = Get-SACStatus
Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "[SUCCÈS] Nouvel état Smart App Control : $($updated.Name)" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan
