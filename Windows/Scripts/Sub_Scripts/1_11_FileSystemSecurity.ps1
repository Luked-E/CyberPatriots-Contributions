[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$WindowsVersion = "Windows 11",

    [Parameter(Mandatory = $false)]
    [ValidateSet("Disabled", "Enabled")]
    [string]$SystemRepair = "Disabled"
)

$ParentDir = [System.IO.Directory]::GetParent($PSScriptRoot).FullName
Import-Module -Name "$ParentDir\EngineUtils.psd1" -Force
Assert-AdminPrivileges

Write-Host "[*] Applying file system, drive security & prohibited media hardening for $WindowsVersion..." -ForegroundColor Cyan

$ErrorActionPreference = 'Stop'
$Drive = "$env:SystemDrive\"

# Recursive file enumeration that logs (instead of hiding) access errors.
function Get-FilesLogged {
    param([string[]]$Path, [string[]]$Include)
    $params = @{ Path = $Path; Recurse = $true; File = $true; Force = $true
                 ErrorAction = "SilentlyContinue"; ErrorVariable = "enumErrors" }
    if ($Include) { $params.Include = $Include }
    $items = Get-ChildItem @params
    foreach ($e in $enumErrors) {
        Write-ErrorLog "Get-ChildItem -Path $($Path -join ',') -Recurse -File -Force | $($e.Exception.Message)"
    }
    $items
}

# 1. Root drive & System32 permissions: remove Everyone (S-1-1-0) grants, then show ACLs for review
foreach ($path in $Drive, "$env:SystemRoot\System32") {
    Invoke-Step "icacls `"$path`" /remove:g *S-1-1-0" {
        try {
            icacls $path /remove:g "*S-1-1-0" 2>&1 | Out-Null
        } catch {
            Write-Host "[!] Note: Could not fully strip Everyone from $path (Protected System ACL)" -ForegroundColor Yellow
        }
    }
    Invoke-Step "icacls `"$path`"" { icacls $path | Out-Host }
}

    # 2. System file integrity repair (DISM first so SFC has a healthy component store)
if (&SystemRepair -eq "Enabled") {
    Invoke-Step 'DISM /Online /Cleanup-Image /RestoreHealth' { DISM /Online /Cleanup-Image /RestoreHealth | Out-Host }
    Invoke-Step 'sfc /scannow' { sfc /scannow | Out-Host }
}

# 3. Hosts file: keep comments/blank lines and localhost entries only
$hosts = "$env:SystemRoot\System32\drivers\etc\hosts"
Invoke-Step "Reset $hosts to localhost-only entries" {
    $clean = Get-Content -LiteralPath $hosts | Where-Object {
        $_ -match '^\s*(#|$)' -or $_ -match '^\s*(127\.0\.0\.1|::1)\s+localhost\s*$'
    }
    Set-ItemProperty -LiteralPath $hosts -Name IsReadOnly -Value $false
    Set-Content -LiteralPath $hosts -Value $clean -Encoding ASCII
}

# 5. NTFS alternate data streams under C:\Users (Zone.Identifier is the benign download marker)
$streams = Get-FilesLogged -Path "$env:SystemDrive\Users" |
    Get-Item -Stream * -ErrorAction SilentlyContinue |
    Where-Object { $_.Stream -notin ':$DATA', "Zone.Identifier" }
foreach ($s in $streams) {
    Write-Host "[!] Alternate data stream: $($s.FileName):$($s.Stream)" -ForegroundColor Red
    Invoke-Step "Remove-Item -LiteralPath '$($s.FileName)' -Stream '$($s.Stream)'" {
        Remove-Item -LiteralPath $s.FileName -Stream $s.Stream
    }
}

# 6. Unattended setup / Sysprep answer files containing passwords
$answerFiles = @(
    "$env:SystemRoot\Panther\Unattend.xml",
    "$env:SystemRoot\Panther\Unattend\Unattend.xml",
    "$env:SystemRoot\System32\sysprep\sysprep.xml",
    "$env:SystemRoot\System32\sysprep\Panther\Unattend.xml"
) | Where-Object { Test-Path -LiteralPath $_ }
foreach ($f in $answerFiles) {
    Write-Host "[!] Setup answer file: $f" -ForegroundColor Red
    Invoke-Step "Select-String -Path '$f' -Pattern Password,PlainText" {
        Select-String -Path $f -Pattern "Password", "PlainText" | Out-Host
    }
}

# 7. Sticky Keys / accessibility backdoors: restore any binary that is a copy of cmd.exe
$system32 = "$env:SystemRoot\System32"
$cmdHash  = (Get-FileHash "$system32\cmd.exe").Hash
foreach ($name in "sethc.exe", "utilman.exe", "osk.exe", "narrator.exe", "magnify.exe") {
    $file = "$system32\$name"
    if (-not (Test-Path -LiteralPath $file)) { continue }
    if ((Get-FileHash $file).Hash -eq $cmdHash) {
        Write-Host "[!] BACKDOOR: $name is a copy of cmd.exe - restoring with sfc..." -ForegroundColor Red
        Invoke-Step "sfc /scanfile=$file" { sfc /scanfile=$file | Out-Host }
    } else {
        Write-Host "[+] $name verified." -ForegroundColor Green
    }
}

Write-Host "[+] Hardening applied successfully. Errors (if any) logged to the Logs directory." -ForegroundColor Green