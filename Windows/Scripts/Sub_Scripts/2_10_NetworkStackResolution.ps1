[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$WindowsVersion = "Windows 11",

    [Parameter(Mandatory = $false)]
    [ValidateSet("BasicDisabled", "Enabled", "GloballyDisabled")]
    [string]$Ipv6State = "BasicDisabled",

    [Parameter(Mandatory = $false)]
    [ValidateSet("Disabled", "Enabled")]
    [string]$NetBiosState = "Disabled",

    [Parameter(Mandatory = $false)]
    [ValidateSet("Disabled", "Enabled")]
    [string]$MulticastNameResolutionState = "Disabled",

    [Parameter(Mandatory = $false)]
    [ValidateSet("Disabled", "Enabled")]
    [string]$WpadServiceState = "Disabled"
)

$ParentDir = [System.IO.Directory]::GetParent($PSScriptRoot).FullName
Import-Module -Name "$ParentDir\EngineUtils.psd1" -Force
Assert-AdminPrivileges

$ErrorActionPreference = "Stop"

Write-Host "[*] Configuring network stack & name resolution for $WindowsVersion (IPv6: $Ipv6State, NetBIOS: $NetBiosState, LLMNR/mDNS: $MulticastNameResolutionState, WPAD service: $WpadServiceState)..." -ForegroundColor Cyan

function Set-ServiceState {
    param([string]$Name, [string]$State)
    Invoke-Step "Set service $Name to $State" {
        $svc = Get-Service -Name $Name -ErrorAction SilentlyContinue
        if (-not $svc) {
            Write-Host "[-] Service '$Name' not found; skipping." -ForegroundColor DarkGray
            return
        }
        if ($State -eq "Disabled") {
            try {
                if ($svc.Status -ne 'Stopped') { Stop-Service -Name $Name -Force -ErrorAction Stop }
            } catch {
                Write-Host "[!] Note: Could not stop service $Name (Protected/Active)" -ForegroundColor Yellow
            }
            Set-Service -Name $Name -StartupType Disabled -ErrorAction SilentlyContinue
        } else {
            Set-Service -Name $Name -StartupType Manual -ErrorAction SilentlyContinue
            if ($svc.Status -ne 'Running') { Start-Service -Name $Name -ErrorAction SilentlyContinue }
        }
    }
}

# --- IPv6 (DisabledComponents + adapter bindings; reboot required to fully apply) ---
#   BasicDisabled    (default) Microsoft-supported "disable": IPv6 stack and bindings stay ON (loopback and internal
#                    Windows components rely on it), IPv4 is preferred (0x20) and all tunnel transitions are off
#                    (0x01: Teredo, 6to4, ISATAP, IP-HTTPS).  DisabledComponents = 0x21
#   Enabled          Windows default. Bindings on, DisabledComponents = 0
#   GloballyDisabled Unsupported by Microsoft. Unbinds IPv6 from all adapters and sets DisabledComponents = 0xFF
#                    (also disables IPv6 on loopback; can break Windows components/services)
$ipv6Components = switch ($Ipv6State) {
    "BasicDisabled"    { 0x21 }
    "Enabled"          { 0x00 }
    "GloballyDisabled" { 0xFF }
}
$ipv6Cmd = if ($Ipv6State -eq "GloballyDisabled") { "Disable-NetAdapterBinding" } else { "Enable-NetAdapterBinding" }
Invoke-Step "$ipv6Cmd -Name * -ComponentID ms_tcpip6" { & $ipv6Cmd -Name "*" -ComponentID ms_tcpip6 }
Set-RegValue "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" "DisabledComponents" $ipv6Components
if ($Ipv6State -eq "GloballyDisabled") {
    Write-Host "[!] IPv6 globally disabled (DisabledComponents=0xFF). Microsoft does not recommend this; use BasicDisabled unless the scenario requires it." -ForegroundColor Yellow
}

# --- NetBIOS over TCP/IP (adapter setting + TCP/IP NetBIOS Helper service) ---
$netbiosOption = if ($NetBiosState -eq "Disabled") { 2 } else { 1 }
$adapters = @()
try {
    $adapters = @(Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration -Filter "IPEnabled = TRUE")
} catch {
    Write-WarningLog -Message "Get-CimInstance Win32_NetworkAdapterConfiguration | $($_.Exception.Message)"
}
foreach ($adapter in $adapters) {
    Invoke-Step "SetTcpipNetbios($netbiosOption) on $($adapter.Description)" {
        $result = Invoke-CimMethod -InputObject $adapter -MethodName SetTcpipNetbios -Arguments @{ TcpipNetbiosOptions = [uint32]$netbiosOption }
        if ($result.ReturnValue -notin 0, 1) { throw "SetTcpipNetbios returned $($result.ReturnValue)" }
    }
}
Set-ServiceState "lmhosts" $NetBiosState

# --- LLMNR + mDNS ("Turn off multicast name resolution" covers LLMNR; EnableMDNS covers mDNS) ---
$multicast = if ($MulticastNameResolutionState -eq "Disabled") { 0 } else { 1 }
Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" "EnableMulticast" $multicast
Set-RegValue "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" "EnableMDNS" $multicast

# --- WinHTTP Web Proxy Auto-Discovery Service (WPAD) ---
Set-ServiceState "WinHttpAutoProxySvc" $WpadServiceState
# WPAD discovery: machine-wide DisableWpad + the "Automatically detect settings" LAN checkbox (current user)
Set-RegValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\WinHttp" "DisableWpad" $(if ($WpadServiceState -eq "Disabled") { 1 } else { 0 })
$connKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Connections"
foreach ($name in "DefaultConnectionSettings", "SavedLegacySettings") {
    Invoke-Step "Set auto-detect flag in $connKey\$name" {
        $blob = (Get-ItemProperty -Path $connKey -Name $name -ErrorAction SilentlyContinue).$name
        if (-not $blob) { $blob = New-Object byte[] 56; $blob[0] = 0x46; $blob[8] = 0x01 }   # default "direct" blob
        $blob[8] = if ($WpadServiceState -eq "Disabled") { $blob[8] -band 0xF7 } else { $blob[8] -bor 0x08 }
        Set-RegValue $connKey $name $blob "Binary"
    }
}

# --- TCP/IP hardening (always applied; most secure value, no feature removed) ---
$tcpip = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
@{
    SynAttackProtect       = 2
    EnableICMPRedirect     = 0
    DisableIPSourceRouting = 2
    PerformRouterDiscovery = 0
}.GetEnumerator() | ForEach-Object { Set-RegValue $tcpip $_.Key $_.Value }

# Per-interface router discovery is what Windows 11 actually honors
Invoke-Step "Set-NetIPInterface -AddressFamily IPv4 -RouterDiscovery Disabled" {
    Get-NetIPInterface -AddressFamily IPv4 |
        Where-Object InterfaceAlias -notlike "Loopback*" |
        Set-NetIPInterface -RouterDiscovery Disabled
}

Write-Host "[+] Network stack & name resolution hardening applied. Errors (if any) are in the Logs directory." -ForegroundColor Green