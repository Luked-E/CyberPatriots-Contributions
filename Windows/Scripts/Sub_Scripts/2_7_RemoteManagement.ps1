[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$WindowsVersion = "Windows 11",

    [Parameter(Mandatory = $false)]
    [ValidateSet("Disabled", "Enabled")]
    [string]$WinRMState = "Disabled",

    [Parameter(Mandatory = $false)]
    [ValidateSet("Disabled", "Enabled")]
    [string]$RemoteRegistryState = "Disabled"
)

$ScriptName = Split-Path -Leaf $PSCommandPath
$ErrorLog   = Join-Path (Get-Location).Path "errors.log"
$ErrorActionPreference = 'Stop'

# Runs one step; any error is appended to errors.log with the file name and command attempted.
function Invoke-Step {
    param([string]$Description, [scriptblock]$Action)
    try {
        & $Action
    } catch {
        Add-Content -Path $ErrorLog -Value ("[{0}] File: {1} | Command: {2} | Error: {3}" -f (Get-Date -Format s), $ScriptName, $Description, $_.Exception.Message)
        Write-Host "[-] Failed: $Description (see errors.log)" -ForegroundColor Red
    }
}

function Set-ServiceState {
    param([string]$Name, [string]$State)
    if ($State -eq "Disabled") {
        Invoke-Step "Stop-Service -Name $Name -Force" { Stop-Service -Name $Name -Force }
        Invoke-Step "Set-Service -Name $Name -StartupType Disabled" { Set-Service -Name $Name -StartupType Disabled }
    } else {
        Invoke-Step "Set-Service -Name $Name -StartupType Automatic" { Set-Service -Name $Name -StartupType Automatic }
        Invoke-Step "Start-Service -Name $Name" { Start-Service -Name $Name }
    }
}

Write-Host "[*] Configuring remote administration for $WindowsVersion (WinRM: $WinRMState, Remote Registry: $RemoteRegistryState)..." -ForegroundColor Cyan

# Hardcoded baseline (policy keys apply whether or not the WinRM service is running):
# no Basic auth, no unencrypted traffic (client and service), and empty TrustedHosts (no wildcard).
$winRMPolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM"
$registrySettings = @(
    @{ Path = "$winRMPolicy\Service"; Name = "AllowBasic";              Value = 0;  Type = "DWord"  }
    @{ Path = "$winRMPolicy\Service"; Name = "AllowUnencryptedTraffic"; Value = 0;  Type = "DWord"  }
    @{ Path = "$winRMPolicy\Client";  Name = "AllowBasic";              Value = 0;  Type = "DWord"  }
    @{ Path = "$winRMPolicy\Client";  Name = "AllowUnencryptedTraffic"; Value = 0;  Type = "DWord"  }
    @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WSMAN\Client"; Name = "trusted_hosts"; Value = ""; Type = "String" }
)

foreach ($s in $registrySettings) {
    Invoke-Step "New-ItemProperty -Path '$($s.Path)' -Name '$($s.Name)' -Value '$($s.Value)' -PropertyType $($s.Type) -Force" {
        if (-not (Test-Path $s.Path)) { New-Item -Path $s.Path -Force | Out-Null }
        New-ItemProperty -Path $s.Path -Name $s.Name -Value $s.Value -PropertyType $s.Type -Force | Out-Null
    }
}

# WinRM / PowerShell Remoting
if ($WinRMState -eq "Disabled") {
    Invoke-Step "Disable-PSRemoting -Force" { Disable-PSRemoting -Force }
    Set-ServiceState -Name "WinRM" -State "Disabled"
} else {
    Invoke-Step "Enable-PSRemoting -Force" { Enable-PSRemoting -Force }
}

# Remote Registry
Set-ServiceState -Name "RemoteRegistry" -State $RemoteRegistryState

Write-Host "[+] Remote administration hardening applied. Any errors were logged to $ErrorLog." -ForegroundColor Green