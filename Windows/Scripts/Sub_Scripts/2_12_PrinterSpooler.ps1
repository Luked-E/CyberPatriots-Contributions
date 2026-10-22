[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$WindowsVersion = "Windows 11",

    # Disabled is safest; choose Enabled only if printing must work.
    [Parameter(Mandatory = $false)]
    [ValidateSet("Disabled", "Enabled")]
    [string]$SpoolerState = "Disabled",

    # Only needed when this machine must act as a print server.
    [Parameter(Mandatory = $false)]
    [switch]$AllowRemotePrinting
)

$ScriptName = Split-Path $PSCommandPath -Leaf
$ErrorLog   = Join-Path (Get-Location) "errors.log"

# Runs an action; on failure appends script name, command and error to errors.log.
function Invoke-Safe {
    param([string]$Command, [scriptblock]$Action)
    try {
        & $Action
    } catch {
        Add-Content -Path $ErrorLog -Value "$(Get-Date -Format s) | $ScriptName | $Command | $($_.Exception.Message)"
        Write-Host "[!] Failed: $Command (see errors.log)" -ForegroundColor Red
    }
}

function Set-RegDword {
    param([string]$Path, [string]$Name, [int]$Value)
    Invoke-Safe "Set-ItemProperty '$Path' '$Name' = $Value" {
        if (-not (Test-Path $Path)) { New-Item -Path $Path -Force -ErrorAction Stop | Out-Null }
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type DWord -ErrorAction Stop
    }
}

Write-Host "[*] Securing Print Spooler & printer drivers for $WindowsVersion (Spooler: $SpoolerState)..." -ForegroundColor Cyan

$Printers = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers"
$PointAndPrint = "$Printers\PointAndPrint"

# 2 & 4. Driver installation restrictions (Point and Print merged: sections 2 and 4 overlap)
Set-RegDword $Printers "KMPrintersAreBlocked" 1                              # Disallow kernel-mode printer drivers
Set-RegDword $PointAndPrint "Restricted" 1                                    # Point and Print Restrictions: Enabled
Set-RegDword $PointAndPrint "TrustedServers" 0
Set-RegDword $PointAndPrint "InForest" 0
Set-RegDword $PointAndPrint "NoWarningNoElevationOnInstall" 0                 # Show warning and elevation prompt (new connection)
Set-RegDword $PointAndPrint "UpdatePromptSettings" 0                          # Show warning and elevation prompt (updates)
Set-RegDword $PointAndPrint "RestrictDriverInstallationToAdministrators" 1    # Limit driver installation to Administrators
Set-RegDword "HKLM:\SYSTEM\CurrentControlSet\Control\Print\Providers\LanMan Print Services\Servers" "AddPrinterDrivers" 1  # Devices: Prevent users from installing printer drivers

# 3. Inbound remote printing (PrintNightmare): 2 = Disabled, 1 = Enabled
Set-RegDword $Printers "RegisterSpoolerRemoteRpcEndPoint" ($(if ($AllowRemotePrinting) { 1 } else { 2 }))

# 1. Print Spooler service state (done last so a restart picks up the policies above)
if ($SpoolerState -eq "Disabled") {
    Invoke-Safe "Stop-Service Spooler; Set-Service Spooler -StartupType Disabled" {
        Stop-Service -Name Spooler -Force -ErrorAction Stop
        Set-Service -Name Spooler -StartupType Disabled -ErrorAction Stop
    }
    Write-Host "[+] Print Spooler disabled." -ForegroundColor Green
} else {
    Invoke-Safe "Set-Service Spooler -StartupType Automatic; Restart-Service Spooler" {
        Set-Service -Name Spooler -StartupType Automatic -ErrorAction Stop
        Restart-Service -Name Spooler -Force -ErrorAction Stop
    }
    Write-Host "[+] Print Spooler enabled with hardened policies." -ForegroundColor Yellow
}

Write-Host "[+] Hardening applied." -ForegroundColor Green