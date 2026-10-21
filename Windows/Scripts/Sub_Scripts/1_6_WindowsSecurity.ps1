[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$WindowsVersion = "Windows 11"
)

# Terminating errors let Invoke-Step catch and log every failure.
$ErrorActionPreference = 'Stop'
$ErrorLog   = Join-Path (Get-Location).Path 'errors.log'
$ScriptName = Split-Path $PSCommandPath -Leaf

Write-Host "[*] Applying Windows Security & Threat Protection hardening for $WindowsVersion..." -ForegroundColor Cyan

# Runs $Action; on failure logs "<script file> | <command attempted> | <error>" to errors.log.
function Invoke-Step {
    param([string]$Command, [scriptblock]$Action)
    try { & $Action }
    catch {
        Write-Host "[-] Failed: $Command" -ForegroundColor Red
        Add-Content -Path $ErrorLog -Value "[$(Get-Date -Format s)] $ScriptName | $Command | $($_.Exception.Message)"
    }
}

function Set-Pref {
    param([string]$Name, $Value)
    $splat = @{ $Name = $Value }
    Invoke-Step "Set-MpPreference -$Name $Value" { Set-MpPreference @splat }
}

function Set-Reg {
    param([string]$Path, [string]$Name, $Value, [string]$Type = 'DWord')
    Invoke-Step "Set-ItemProperty $Path $Name = $Value" {
        if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
        New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
    }
}

# 1. Virus & Threat Protection: real-time, cloud-delivered, automatic sample submission,
#    plus sections 4 (Controlled Folder Access), 6 (PUA) and 7 (Network Protection)
Set-Pref DisableRealtimeMonitoring $false
Set-Pref MAPSReporting             'Advanced'
Set-Pref SubmitSamplesConsent      'SendSafeSamples'
Set-Pref EnableControlledFolderAccess 'Enabled'
Set-Pref PUAProtection             'Enabled'
Set-Pref EnableNetworkProtection   'Enabled'

# 1. Remove all scan exclusions (backdoor point)
foreach ($type in 'ExclusionPath', 'ExclusionProcess', 'ExclusionExtension', 'ExclusionIpAddress') {
    Invoke-Step "Remove-MpPreference -$type" {
        $values = @((Get-MpPreference).$type | Where-Object { $_ })
        if ($values) {
            $splat = @{ $type = $values }
            Remove-MpPreference @splat
            Write-Host "[+] Removed $type entries: $($values -join '; ')" -ForegroundColor Yellow
        }
    }
}

# 1. Full scan, launched detached so the orchestrator is not blocked for the scan duration
Invoke-Step 'Start-MpScan -ScanType FullScan' {
    Start-Process powershell.exe -WindowStyle Hidden -ArgumentList '-NoProfile', '-Command', 'Start-MpScan -ScanType FullScan'
}

# 2. SmartScreen (Block is the most secure option)
$policySystem = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'
Set-Reg $policySystem 'EnableSmartScreen'     1
Set-Reg $policySystem 'ShellSmartScreenLevel' 'Block' 'String'
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' 'SmartScreenEnabled' 1
$appHost = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AppHost'
Set-Reg $appHost 'EnableWebContentEvaluation' 1
Set-Reg $appHost 'PreventOverride'            1

# 3. Tamper Protection cannot be set by script (Defender protects the setting); verify only
Invoke-Step 'Get-MpComputerStatus (IsTamperProtected)' {
    if (-not (Get-MpComputerStatus).IsTamperProtected) {
        Write-Host "[!] Tamper Protection is OFF. Turn it on manually: Windows Security > Virus & threat protection settings > Manage settings." -ForegroundColor Yellow
    }
}

# 5. System-wide exploit protection: CFG, DEP, Mandatory ASLR (+ bottom-up), SEHOP, heap integrity
Invoke-Step 'Set-ProcessMitigation -System -Enable CFG,DEP,BottomUp,ForceRelocateImages,SEHOP,TerminateOnError' {
    Set-ProcessMitigation -System -Enable CFG, DEP, BottomUp, ForceRelocateImages, SEHOP, TerminateOnError
}

Write-Host "[+] Hardening applied. Any failures were logged to $ErrorLog" -ForegroundColor Green
