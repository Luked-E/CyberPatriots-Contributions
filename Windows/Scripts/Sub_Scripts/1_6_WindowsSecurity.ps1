[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$WindowsVersion = "Windows 11"
)

$ParentDir = [System.IO.Directory]::GetParent($PSScriptRoot).FullName
Import-Module -Name "$ParentDir\EngineUtils.psd1" -Force
Assert-AdminPrivileges

# Terminating errors let Invoke-Step catch and log every failure.
$ErrorActionPreference = 'Stop'

Write-Host "[*] Applying Windows Security & Threat Protection hardening for $WindowsVersion..." -ForegroundColor Cyan

function Set-Pref {
    param([string]$Name, $Value)
    $splat = @{ $Name = $Value }
    Invoke-Step "Set-MpPreference -$Name $Value" { Set-MpPreference @splat }
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
Set-RegValue $policySystem 'EnableSmartScreen'     1
Set-RegValue $policySystem 'ShellSmartScreenLevel' 'Block' 'String'
Set-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' 'SmartScreenEnabled' 1
$appHost = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AppHost'
Set-RegValue $appHost 'EnableWebContentEvaluation' 1
Set-RegValue $appHost 'PreventOverride'            1

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

Write-Host "[+] Hardening applied. Any failures were logged to the Logs directory." -ForegroundColor Green