[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$WindowsVersion = "Windows 11"
)

$ErrorActionPreference = 'Stop'
$ScriptName = $MyInvocation.MyCommand.Name
$ErrorLog   = Join-Path (Get-Location).Path 'errors.log'
$System32   = Join-Path $env:SystemRoot 'System32'

# Rogue names from the Task Manager audit list (dual extension, netcat, meterpreter, adware/trojans, torrent tools)
$RoguePattern = '\bnc\.exe|\bncat|netcat|meterpreter|SharpChrome|IOTransfer|torrent|\.exe\.exe'
$CoreNames    = 'svchost.exe', 'lsass.exe', 'csrss.exe', 'services.exe'

# Runs an action; on failure logs "file | command | error" to errors.log in the current directory.
function Invoke-Step {
    param([string]$Command, [scriptblock]$Action)
    try {
        $global:LASTEXITCODE = 0
        & $Action
        if ($LASTEXITCODE -ne 0) { throw "Exit code $LASTEXITCODE" }
        Write-Host "[+] $Command" -ForegroundColor Green
    } catch {
        Add-Content -Path $ErrorLog -Value "[$(Get-Date -Format s)] $ScriptName | $Command | $($_.Exception.Message)"
        Write-Host "[!] Failed: $Command" -ForegroundColor Red
    }
}

Write-Host "[*] Applying Task Manager hardening for $WindowsVersion..." -ForegroundColor Cyan

# --- 1. Startup Applications: remove rogue Run/RunOnce entries and Startup-folder items ---
$RunKeys = foreach ($hive in 'HKLM', 'HKCU') {
    "${hive}:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
    "${hive}:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
}
$RunKeys += 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run'

foreach ($key in $RunKeys) {
    $item = Get-Item -Path $key -ErrorAction SilentlyContinue
    if (-not $item) { continue }
    foreach ($name in $item.GetValueNames() | Where-Object { $_ -and "$($item.GetValue($_))" -match $RoguePattern }) {
        Invoke-Step "Remove-ItemProperty -Path $key -Name '$name'" { Remove-ItemProperty -Path $key -Name $name }
    }
}

foreach ($dir in "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup", "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup") {
    Get-ChildItem -LiteralPath $dir -File -Force -ErrorAction SilentlyContinue | Where-Object Name -match $RoguePattern | ForEach-Object {
        $file = $_.FullName
        Invoke-Step "Remove-Item -LiteralPath '$file' -Force" { Remove-Item -LiteralPath $file -Force }
    }
}

# --- 2 & 3. Running processes: rogue names, and core system binaries running outside System32 ---
$procs = Get-CimInstance -ClassName Win32_Process

$rogue = $procs | Where-Object {
    $_.Name -match $RoguePattern -or
    ($_.Name -in $CoreNames -and $_.ExecutablePath -and $_.ExecutablePath -notlike "$System32\*")
}
foreach ($p in $rogue) {
    $id = $p.ProcessId; $path = $p.ExecutablePath
    Invoke-Step "taskkill /PID $id /T /F ($($p.Name))" {
        if (Get-Process -Id $id -ErrorAction SilentlyContinue) { taskkill /PID $id /T /F | Out-Null }
    }
    if ($path) {
        Invoke-Step "Remove-Item -LiteralPath '$path' -Force" {
            if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Force }
        }
    }
}

# Command-line triage is report-only (legitimate tools also use these flags). Skip this script's own process chain.
$self = @(); $id = $PID
while ($id -and $id -notin $self) {
    $self += $id
    $id = ($procs | Where-Object ProcessId -eq $id).ParentProcessId
}
$procs | Where-Object { $_.ProcessId -notin $self -and $_.CommandLine -match '-enc|bypass|hidden' } | ForEach-Object {
    Write-Host "[?] Investigate PID $($_.ProcessId) $($_.Name): $($_.CommandLine)" -ForegroundColor Yellow
}

# --- 4. Services: stop and disable services whose binary matches a rogue name ---
Get-CimInstance -ClassName Win32_Service | Where-Object { $_.PathName -match $RoguePattern } | ForEach-Object {
    $svc = $_.Name
    Invoke-Step "Stop-Service -Name '$svc' -Force" { Stop-Service -Name $svc -Force }
    Invoke-Step "Set-Service -Name '$svc' -StartupType Disabled" { Set-Service -Name $svc -StartupType Disabled }
}

# --- 5. Users: sign off disconnected (ghost) sessions ---
if (Get-Command quser -ErrorAction SilentlyContinue) {
    quser 2>$null | Select-String '^\s*>?\S+\s+(\d+)\s+Disc' | ForEach-Object {
        $sid = $_.Matches[0].Groups[1].Value
        Invoke-Step "logoff $sid" { logoff $sid }
    }
} else {
    Write-Host "[*] 'quser' command not available on this Windows edition; skipping ghost session check." -ForegroundColor DarkGray
}