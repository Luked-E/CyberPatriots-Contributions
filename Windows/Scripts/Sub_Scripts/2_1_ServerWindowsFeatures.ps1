[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$WindowsVersion = "Windows 11",

    [Parameter(Mandatory = $false)]
    [switch]$KeepIIS,

    [Parameter(Mandatory = $false)]
    [switch]$KeepFTP,

    [Parameter(Mandatory = $false)]
    [switch]$KeepADDS,

    [Parameter(Mandatory = $false)]
    [switch]$KeepDHCP,

    [Parameter(Mandatory = $false)]
    [switch]$KeepRDS,

    [Parameter(Mandatory = $false)]
    [switch]$KeepADCS,

    [Parameter(Mandatory = $false)]
    [switch]$KeepVirtualMachinePlatform
)

$ScriptName = Split-Path -Leaf $PSCommandPath
$ErrorLog   = Join-Path (Get-Location).Path "errors.log"
$IsServer   = $WindowsVersion -like "*Server*"

Write-Host "[*] Applying Windows features hardening for $WindowsVersion..." -ForegroundColor Cyan

# Runs an action; on failure logs script name, command attempted and error to errors.log
function Invoke-Safe {
    param([string]$Command, [scriptblock]$Action)
    try { & $Action }
    catch {
        Add-Content -Path $ErrorLog -Value "[$(Get-Date -Format s)] $ScriptName | Command: $Command | Error: $($_.Exception.Message)"
        Write-Host "[-] Failed: $Command" -ForegroundColor Red
    }
}

# Returns names that match any wildcard pattern
function Select-Match {
    param([string[]]$Names, [string[]]$Patterns)
    $Names | Where-Object { $n = $_; $Patterns | Where-Object { $n -like $_ } }
}

# Disables every enabled optional feature matching the patterns in a single DISM call
function Disable-Optional {
    param([string[]]$Patterns)
    $names = @(Select-Match $script:EnabledOptional $Patterns)
    if (-not $names) { return }
    Invoke-Safe "Disable-WindowsOptionalFeature -Online -FeatureName $($names -join ',') -NoRestart" {
        Disable-WindowsOptionalFeature -Online -FeatureName $names -NoRestart -ErrorAction Stop | Out-Null
        Write-Host "[+] Disabled: $($names -join ', ')" -ForegroundColor Green
    }
}

# Features shared by every OS: WSL, Windows Sandbox, and VM Platform (kept only if Credential Guard needs it)
$sharedPatterns = @("Microsoft-Windows-Subsystem-Linux", "Containers-DisposableClientVM")
if (-not $KeepVirtualMachinePlatform) { $sharedPatterns += "VirtualMachinePlatform" }

$script:EnabledOptional = @()
Invoke-Safe "Get-WindowsOptionalFeature -Online" {
    $script:EnabledOptional = @((Get-WindowsOptionalFeature -Online -ErrorAction Stop | Where-Object State -eq "Enabled").FeatureName)
    # Shield IIS FTP and the IIS role it requires from the broad IIS-* match
    if ($KeepFTP) { $script:EnabledOptional = @($script:EnabledOptional | Where-Object { $_ -notmatch "^(IIS-FTP|IIS-WebServerRole$)" }) }
}

if ($IsServer) {
    # Server Manager roles and features (Remove-WindowsFeature works on 2008 R2 through 2022)
    $serverPatterns = @(
        "Print-*", "FS-SMB1", "Telnet-*", "Simple-TCPIP", "Windows-Internal-Database", "XPS-Viewer"
    )
    if (-not $KeepFTP)  { $serverPatterns += "TFTP-Client" }
    if (-not $KeepADDS) { $serverPatterns += "AD-Domain-Services" }
    if (-not $KeepDHCP) { $serverPatterns += "DHCP" }
    if (-not $KeepRDS)  { $serverPatterns += "RDS-*", "Remote-Desktop-Services" }
    if (-not $KeepADCS) { $serverPatterns += "ADCS-*" }

    Invoke-Safe "Import-Module ServerManager" { Import-Module ServerManager -ErrorAction Stop }
    Invoke-Safe "Get-WindowsFeature | Where-Object Installed" {
        $installed = @((Get-WindowsFeature -ErrorAction Stop | Where-Object Installed).Name)
        $remove = @(Select-Match $installed $serverPatterns)
        if ($remove) {
            Invoke-Safe "Remove-WindowsFeature -Name $($remove -join ',')" {
                Remove-WindowsFeature -Name $remove -ErrorAction Stop | Out-Null
                Write-Host "[+] Removed: $($remove -join ', ')" -ForegroundColor Green
            }
        }
    }
    Disable-Optional $sharedPatterns
}
else {
    # Windows 10 / 11 optional features
    $clientPatterns = @(
        "SMB1Protocol*", "TelnetClient", "SimpleTCP",
        "Printing-Foundation-InternetPrinting-Client"
    )
    if (-not $KeepFTP) { $clientPatterns += "TFTP", "IIS-FTP*" }
    if (-not $KeepIIS) { $clientPatterns += "IIS-*" }
    Disable-Optional ($clientPatterns + $sharedPatterns)
}

# Audit: list optional features still enabled
Invoke-Safe "Get-WindowsOptionalFeature -Online | Where-Object State -eq Enabled" {
    Write-Host "[*] Optional features still enabled:" -ForegroundColor Cyan
    Get-WindowsOptionalFeature -Online -ErrorAction Stop | Where-Object State -eq "Enabled" |
        Select-Object FeatureName | Sort-Object FeatureName | Format-Table -HideTableHeaders | Out-Host
}

Write-Host "[+] Windows features hardening applied. Reboot if required." -ForegroundColor Green