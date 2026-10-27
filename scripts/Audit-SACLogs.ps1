param (
    [Parameter(Mandatory = $false)]
    [int]$Limit = 25
)

# Configuration Encodage UTF-8 Standard (Antigravity)
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding           = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   WinSmartControl - Audit des Ã‰vÃ©nements Code Integrity  " -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "[*] Recherche des $Limit derniers Ã©vÃ©nements Code Integrity (ID 3076=Audit, 3077=BloquÃ©)..." -ForegroundColor Gray

$logName = "Microsoft-Windows-CodeIntegrity/Operational"
$events = Get-WinEvent -FilterHashtable @{LogName=$logName; Id=3076,3077} -MaxEvents $Limit -ErrorAction SilentlyContinue

if (-not $events -or $events.Count -eq 0) {
    Write-Host "[OK] Aucun Ã©vÃ©nement de blocage ou d'audit Smart App Control trouvÃ© rÃ©cemment." -ForegroundColor Green
    exit 0
}

Write-Host "[+] $($events.Count) Ã©vÃ©nement(s) dÃ©tectÃ©(s) :" -ForegroundColor Yellow
foreach ($ev in $events) {
    $type = if ($ev.Id -eq 3076) { "[AUDIT / NON BLOQUÃ‰]" } else { "[BLOQUÃ‰ / ENFORCED]" }
    $color = if ($ev.Id -eq 3076) { "Yellow" } else { "Red" }
    
    Write-Host "`n$type Horodatage: $($ev.TimeCreated)" -ForegroundColor $color
    Write-Host "Message: $($ev.Message.Trim())" -ForegroundColor Gray
}
