[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$WindowsVersion = "Windows 11"
)

Write-Host "[*] Applying file system, drive security & prohibited media hardening for $WindowsVersion..." -ForegroundColor Cyan

$ScriptName = $MyInvocation.MyCommand.Name
$ErrorLog   = Join-Path (Get-Location).Path "errors.log"
$Drive      = "$env:SystemDrive\"

function Write-ErrorLog {
    param([string]$Command, [string]$Message)
    Add-Content -Path $ErrorLog -Value "[$(Get-Date -Format s)] $ScriptName | $Command | $Message"
    Write-Host "[-] $Command failed: $Message" -ForegroundColor Red
}

# Runs an action; logs any terminating error or non-zero native exit code.
function Invoke-Step {
    param([string]$Command, [scriptblock]$Action)
    $ErrorActionPreference = "Stop"
    try {
        $global:LASTEXITCODE = 0
        & $Action
        if ($global:LASTEXITCODE -ne 0) { throw "Exit code $global:LASTEXITCODE" }
    } catch {
        Write-ErrorLog $Command $_.Exception.Message
    }
}

# Recursive file enumeration that logs (instead of hiding) access errors.
function Get-FilesLogged {
    param([string[]]$Path, [string[]]$Include)
    $params = @{ Path = $Path; Recurse = $true; File = $true; Force = $true
                 ErrorAction = "SilentlyContinue"; ErrorVariable = "enumErrors" }
    if ($Include) { $params.Include = $Include }
    $items = Get-ChildItem @params
    foreach ($e in $enumErrors) {
        Write-ErrorLog "Get-ChildItem -Path $($Path -join ',') -Recurse -File -Force" $e.Exception.Message
    }
    $items
}

# 1. Root drive & System32 permissions: remove Everyone (S-1-1-0) grants, then show ACLs for review
foreach ($path in $Drive, "$env:SystemRoot\System32") {
    Invoke-Step "icacls `"$path`" /remove:g *S-1-1-0" { icacls $path /remove:g "*S-1-1-0" }
    Invoke-Step "icacls `"$path`"" { icacls $path }
}

# 2. Hosts file: keep comments/blank lines and localhost entries only
$hosts = "$env:SystemRoot\System32\drivers\etc\hosts"
Invoke-Step "Reset $hosts to localhost-only entries" {
    $clean = Get-Content -LiteralPath $hosts | Where-Object {
        $_ -match '^\s*(#|$)' -or $_ -match '^\s*(127\.0\.0\.1|::1)\s+localhost\s*$'
    }
    Set-ItemProperty -LiteralPath $hosts -Name IsReadOnly -Value $false
    Set-Content -LiteralPath $hosts -Value $clean -Encoding ASCII
}

# 4. NTFS alternate data streams under C:\Users (Zone.Identifier is the benign download marker)
$streams = Get-FilesLogged -Path "$env:SystemDrive\Users" |
    Get-Item -Stream * -ErrorAction SilentlyContinue |
    Where-Object { $_.Stream -notin ':$DATA', "Zone.Identifier" }
foreach ($s in $streams) {
    Write-Host "[!] Alternate data stream: $($s.FileName):$($s.Stream)" -ForegroundColor Red
    Invoke-Step "Remove-Item -LiteralPath '$($s.FileName)' -Stream '$($s.Stream)'" {
        Remove-Item -LiteralPath $s.FileName -Stream $s.Stream
    }
}

# 5. Unattended setup / Sysprep answer files containing passwords
$answerFiles = @(
    "$env:SystemRoot\Panther\Unattend.xml",
    "$env:SystemRoot\Panther\Unattend\Unattend.xml",
    "$env:SystemRoot\System32\sysprep\sysprep.xml",
    "$env:SystemRoot\System32\sysprep\Panther\Unattend.xml"
) | Where-Object { Test-Path -LiteralPath $_ }
foreach ($f in $answerFiles) {
    Write-Host "[!] Setup answer file: $f" -ForegroundColor Red
    Invoke-Step "Select-String -Path '$f' -Pattern Password,PlainText" {
        Select-String -Path $f -Pattern "Password", "PlainText"
    }
}

# 6. Sticky Keys / accessibility backdoors: restore any binary that is a copy of cmd.exe
$system32 = "$env:SystemRoot\System32"
$cmdHash  = (Get-FileHash "$system32\cmd.exe").Hash
foreach ($name in "sethc.exe", "utilman.exe", "osk.exe", "narrator.exe", "magnify.exe") {
    $file = "$system32\$name"
    if (-not (Test-Path -LiteralPath $file)) { continue }
    if ((Get-FileHash $file).Hash -eq $cmdHash) {
        Write-Host "[!] BACKDOOR: $name is a copy of cmd.exe - restoring with sfc..." -ForegroundColor Red
        Invoke-Step "sfc /scanfile=$file" { sfc /scanfile=$file }
    } else {
        Write-Host "[+] $name verified." -ForegroundColor Green
    }
}

Write-Host "[+] Hardening applied successfully. Errors (if any) logged to $ErrorLog" -ForegroundColor Green