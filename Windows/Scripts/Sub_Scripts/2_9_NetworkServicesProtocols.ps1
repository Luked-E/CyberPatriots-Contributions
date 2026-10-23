[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$WindowsVersion = "Windows 11",

    # Services a README may require. Default is the secure state.
    [ValidateSet("Disabled", "Enabled")][string]$WebServerState = "Disabled",      # W3SVC
    [ValidateSet("Disabled", "Enabled")][string]$SnmpTrapState = "Disabled",       # SNMPTRAP
    [ValidateSet("Disabled", "Enabled")][string]$UpnpState = "Disabled",           # upnphost + SSDPSRV
    [ValidateSet("Disabled", "Enabled")][string]$BluetoothState = "Disabled",      # bthserv
    [ValidateSet("Disabled", "Enabled")][string]$RdpRedirectorState = "Disabled"   # UmRdpService
)

$ParentDir = [System.IO.Directory]::GetParent($PSScriptRoot).FullName
Import-Module -Name "$ParentDir\EngineUtils.psd1" -Force
Assert-AdminPrivileges

$ErrorActionPreference = 'Stop'

Write-Host "[*] Configuring network services & legacy protocols for $WindowsVersion..." -ForegroundColor Cyan

# Sets startup type and running state. Only touches services that exist and differ from the target.
function Set-ServiceState {
    param([string]$Name, [ValidateSet("Disabled", "Enabled")][string]$State)

    $svc = Get-Service -Name $Name -ErrorAction SilentlyContinue
    if (-not $svc) { 
        Write-Host "[-] $Name not installed, skipping." -ForegroundColor DarkGray
        return 
    }

    $startup = if ($State -eq "Disabled") { "Disabled" } else { "Automatic" }

    try {
        if ($svc.StartType -ne $startup) {
            Invoke-Step "Set-Service -Name $Name -StartupType $startup" {
                Set-Service -Name $Name -StartupType $startup -ErrorAction Stop
            }
        }
        if ($State -eq "Disabled" -and $svc.Status -ne "Stopped") {
            Invoke-Step "Stop-Service -Name $Name -Force" { Stop-Service -Name $Name -Force -ErrorAction Stop }
        }
        elseif ($State -eq "Enabled" -and $svc.Status -ne "Running") {
            Invoke-Step "Start-Service -Name $Name" { Start-Service -Name $Name -ErrorAction Stop }
        }
        Write-Host "[+] $Name -> $State" -ForegroundColor Green
    } catch {
        Write-Host "[!] Note: Could not modify service $Name (Protected or Restricted)" -ForegroundColor Yellow
    }
}

# Always disabled (insecure legacy services, gaming, maps)
$alwaysDisabled = @(
    "ftpsvc", "TlntSvr", "SimpTcp", "RipListener", "RpcLocator", "SharedAccess", "RemoteRegistry", "Browser", "RemoteAccess",
    "XboxGipSvc", "XblAuthManager", "XblGameSave", "XboxNetApiSvc", "MapsBroker"
)

# Always enabled (vital services)
$alwaysEnabled = @(
    "wuauserv", "EventLog", "MpsSvc", "WinDefend", "Dnscache", "LanmanServer", "LanmanWorkstation", "Dhcp"
)

# Option-driven services
$optional = [ordered]@{
    W3SVC        = $WebServerState
    SNMPTRAP     = $SnmpTrapState
    upnphost     = $UpnpState
    SSDPSRV      = $UpnpState
    bthserv      = $BluetoothState
    UmRdpService = $RdpRedirectorState
}

$alwaysDisabled | ForEach-Object { Set-ServiceState -Name $_ -State "Disabled" }
$alwaysEnabled  | ForEach-Object { Set-ServiceState -Name $_ -State "Enabled" }
foreach ($name in $optional.Keys) { Set-ServiceState -Name $name -State $optional[$name] }

Write-Host "[+] Network services & legacy protocols hardening complete. Errors (if any) are in the Logs directory." -ForegroundColor Green