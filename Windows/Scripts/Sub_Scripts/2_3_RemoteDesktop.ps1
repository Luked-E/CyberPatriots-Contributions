[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$WindowsVersion = "Windows 11",

    [Parameter(Mandatory = $false)]
    [ValidateSet("Disabled", "Enabled")]
    [string]$RDPState = "Disabled"
)

$ParentDir = [System.IO.Directory]::GetParent($PSScriptRoot).FullName
Import-Module -Name "$ParentDir\EngineUtils.psd1" -Force
Assert-AdminPrivileges

$ErrorActionPreference = 'Stop'
$enable = $RDPState -eq 'Enabled'

Write-Host "[*] Configuring Remote Desktop Services for $WindowsVersion (Target State: $RDPState)..." -ForegroundColor Cyan

$ts     = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server'
$policy = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
$deny   = [int](-not $enable)

# Registry values: Path, Name, Value (DWord). Secure values are hardcoded.
$settings = @(
    # Sections 1 & 2: one key drives both the Settings toggle and sysdm.cpl; NLA always required
    , @($ts, 'fDenyTSConnections', $deny)
    , @("$ts\WinStations\RDP-Tcp", 'UserAuthentication', 1)
    # Remote Assistance always off
    , @('HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance', 'fAllowToGetHelp', 0)
    # Section 4: Session Host security + time limits (ms)
    , @($policy, 'fAllowToGetHelp', 0)
    , @($policy, 'fEncryptRPCTraffic', 1)
    , @($policy, 'MinEncryptionLevel', 3)          # High
    , @($policy, 'SecurityLayer', 2)               # SSL (TLS)
    , @($policy, 'UserAuthentication', 1)          # NLA
    , @($policy, 'MaxIdleTime', 1800000)           # 30 minutes
    , @($policy, 'MaxDisconnectionTime', 60000)    # 1 minute
    # Section 9: device redirection
    , @($policy, 'fDisableCdm', 1)                 # Drives
    , @($policy, 'fDisableCcm', 1)                 # COM ports
    , @($policy, 'fDisableLPT', 1)                 # LPT ports
    # Section 7: Require Restricted Admin
    , @('HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation', 'RestrictedRemoteAdministration', 1)
    , @('HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation', 'RestrictedRemoteAdministrationType', 1)
)

# If a policy already overrides the connection toggle, keep it in sync so the GUI isn't locked to a stale value.
if ($null -ne (Get-ItemProperty -Path $policy -Name fDenyTSConnections -ErrorAction SilentlyContinue)) {
    $settings += , @($policy, 'fDenyTSConnections', $deny)
}

foreach ($s in $settings) {
    $path, $name, $value = $s
    Set-RegValue -Path $path -Name $name -Value $value -Type DWord
}

# Section 5: services
foreach ($svc in 'UmRdpService', 'SessionEnv', 'TermService') {
    $startup = if (-not $enable) { 'Disabled' } elseif ($svc -eq 'TermService') { 'Automatic' } else { 'Manual' }
    Invoke-Step -Action { Set-Service -Name $svc -StartupType $startup }
    if (-not $enable) { Invoke-Step -Action { Stop-Service -Name $svc -Force } }
}
if ($enable) { Invoke-Step -Action { Start-Service -Name TermService } }

# Section 6: firewall (built-in "Remote Desktop" group, locale-independent ID)
$rdpGroup  = '@FirewallAPI.dll,-28752'
$blockRule = 'Block-RDP-Inbound-3389'
$hasBlock  = [bool](Get-NetFirewallRule -DisplayName $blockRule -ErrorAction SilentlyContinue)

if ($enable) {
    if ($hasBlock) { Invoke-Step -Action { Remove-NetFirewallRule -DisplayName $blockRule } }
    Invoke-Step -Action { Enable-NetFirewallRule -Group $rdpGroup }
} else {
    Invoke-Step -Action { Disable-NetFirewallRule -Group $rdpGroup }
    if (-not $hasBlock) {
        Invoke-Step -Action { New-NetFirewallRule -DisplayName $blockRule -Direction Inbound -Protocol TCP -LocalPort 3389 -Action Block -Profile Any | Out-Null }
    }
}

if ($enable) {
    Write-Host "[+] Remote Desktop enabled with NLA and hardened policies." -ForegroundColor Yellow
} else {
    Write-Host "[+] Remote Desktop disabled and hardened." -ForegroundColor Green
}