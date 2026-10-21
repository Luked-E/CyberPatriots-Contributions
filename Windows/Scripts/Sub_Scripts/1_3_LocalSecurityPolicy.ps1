[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$WindowsVersion = "Windows 11",

    # Not exposed in the manifest (the TUI has no free-text option type); override from the CLI if needed.
    [Parameter(Mandatory = $false)]
    [string]$AdminNewName = "Saxon",

    [Parameter(Mandatory = $false)]
    [string]$GuestNewName = "NotSaxon"
)

$ErrorActionPreference = 'Stop'
$ScriptName = Split-Path $PSCommandPath -Leaf
$ErrorLog   = Join-Path $PWD.Path 'errors.log'
$Failures   = 0

# Runs one step; on any error (including non-zero native exit codes) logs file name + command to errors.log.
function Invoke-Step {
    param([scriptblock]$Action, [string]$Command = $Action.ToString().Trim())
    try {
        $global:LASTEXITCODE = 0
        & $Action | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "Exit code $LASTEXITCODE" }
    } catch {
        $script:Failures++
        Add-Content -Path $ErrorLog -Value "[$(Get-Date -Format s)] $ScriptName | $Command | $($_.Exception.Message)"
        Write-Host "[!] Failed: $Command" -ForegroundColor Red
    }
}

Write-Host "[*] Applying Local Security Policy hardening for $WindowsVersion..." -ForegroundColor Cyan

# ---------------------------------------------------------------------------
# 1. Registry-backed Security Options (what secpol.msc writes under the hood)
# ---------------------------------------------------------------------------
$Sys = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
$Win = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
$Lsa = 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa'

$RegistrySettings = @"
Path|Name|Type|Value
$Lsa|LimitBlankPasswordUse|DWord|1
$Lsa|CrashOnAuditFail|DWord|1
$Lsa|SCENoApplyLegacyAuditPolicy|DWord|1
$Lsa\MSV1_0|AllowNullSessionFallback|DWord|0
$Lsa\pku2u|AllowOnlineID|DWord|0
HKLM:\SYSTEM\CurrentControlSet\Control\Print\Providers\LanMan Print Services\Servers|AddPrinterDrivers|DWord|1
HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management|ClearPageFileAtShutdown|DWord|1
HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Setup\RecoveryConsole|SecurityLevel|DWord|0
HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Setup\RecoveryConsole|SetCommand|DWord|0
$Win|AllocateDASD|String|0
$Win|AllocateCDRoms|String|1
$Win|AllocateFloppies|String|1
$Win|CachedLogonsCount|String|0
$Win|PasswordExpiryWarning|DWord|14
$Sys|UndockWithoutLogon|DWord|0
$Sys|DontDisplayLastUserName|DWord|1
$Sys|DisableCAD|DWord|0
$Sys|LegalNoticeText|String|Authorized Use Only. All activities are monitored and logged.
$Sys|LegalNoticeCaption|String|WARNING: Legal Notice
$Sys|DontDisplayLockedUserId|DWord|3
$Sys|InactivityTimeoutSecs|DWord|300
$Sys|ShutdownWithoutLogon|DWord|0
$Sys|NoConnectedUser|DWord|3
$Sys|FilterAdministratorToken|DWord|1
$Sys|EnableUIADesktopToggle|DWord|0
$Sys|ConsentPromptBehaviorAdmin|DWord|2
$Sys|ConsentPromptBehaviorUser|DWord|0
$Sys|EnableInstallerDetection|DWord|1
$Sys|ValidateAdminCodeSignatures|DWord|1
$Sys|EnableLUA|DWord|1
$Sys|PromptOnSecureDesktop|DWord|1
"@ | ConvertFrom-Csv -Delimiter '|'

foreach ($s in $RegistrySettings) {
    Invoke-Step {
        if (-not (Test-Path $s.Path)) { New-Item -Path $s.Path -Force | Out-Null }
        $value = if ($s.Type -eq 'DWord') { [int]$s.Value } else { $s.Value }
        New-ItemProperty -Path $s.Path -Name $s.Name -PropertyType $s.Type -Value $value -Force
    } "Set $($s.Path)\$($s.Name) = $($s.Value)"
}

# ---------------------------------------------------------------------------
# 2. Audit policy: Success + Failure on every category/subcategory
#    (covers both the legacy Audit Policy and Advanced Audit Policy sections)
# ---------------------------------------------------------------------------
Invoke-Step { auditpol /set '/category:*' /success:enable /failure:enable }

# ---------------------------------------------------------------------------
# 3. Account policies, account status/renames, and User Rights via one secedit import
# ---------------------------------------------------------------------------
# Only disable the built-in Administrator if another enabled local admin exists.
$HasOtherAdmin = $false
Invoke-Step {
    $script:HasOtherAdmin = [bool](
        Get-LocalGroupMember -SID 'S-1-5-32-544' |
            Where-Object { $_.ObjectClass -eq 'User' -and $_.SID.Value -notlike '*-500' } |
            ForEach-Object { Get-LocalUser -SID $_.SID -ErrorAction SilentlyContinue } |
            Where-Object Enabled)
} "Check for another enabled local administrator"

if (-not $HasOtherAdmin) {
    Write-Warning "No other enabled local administrator found - leaving the built-in Administrator enabled."
}

$AccountPolicy = [ordered]@{
    MinimumPasswordAge     = 3
    MaximumPasswordAge     = 30
    MinimumPasswordLength  = 14
    PasswordComplexity     = 1
    PasswordHistorySize    = 24
    ClearTextPassword      = 0
    LockoutBadCount        = 5
    LockoutDuration        = 30
    ResetLockoutCount      = 30
    EnableGuestAccount     = 0
    NewAdministratorName   = "`"$AdminNewName`""
    NewGuestName           = "`"$GuestNewName`""
}
if ($HasOtherAdmin) { $AccountPolicy['EnableAdminAccount'] = 0 }

$Admins = '*S-1-5-32-544'
$Guests = '*S-1-5-32-546'
$PrivilegeRights = [ordered]@{
    SeNetworkLogonRight               = "$Admins,*S-1-5-11"                               # Administrators, Authenticated Users
    SeInteractiveLogonRight           = "$Admins,*S-1-5-32-545"                           # Administrators, Users (keeps console users able to log on)
    SeChangeNotifyPrivilege           = "$Admins,*S-1-5-11,*S-1-5-19,*S-1-5-20,*S-1-5-90-0" # Bypass traverse checking: Everyone/Users removed; services + DWM kept
    SeDenyNetworkLogonRight           = "*S-1-5-7,$Guests"                                # ANONYMOUS LOGON, Guests
    SeRemoteShutdownPrivilege         = $Admins
    SeAuditPrivilege                  = '*S-1-5-19,*S-1-5-20'                             # LOCAL SERVICE, NETWORK SERVICE
    SeServiceLogonRight               = '*S-1-5-18,*S-1-5-19,*S-1-5-20,*S-1-5-80-0'       # SYSTEM, LOCAL/NETWORK SERVICE, NT SERVICE\ALL SERVICES
    SeRestorePrivilege                = $Admins
    SeShutdownPrivilege               = "$Admins,*S-1-5-32-551"                           # Administrators, Backup Operators
    SeTcbPrivilege                    = ''                                                # Act as part of the OS: nobody
    SeDenyInteractiveLogonRight       = $Guests
    SeDenyRemoteInteractiveLogonRight = "$Guests,*S-1-5-7"
    SeDenyBatchLogonRight             = $Guests
    SeDenyServiceLogonRight           = $Guests
    SeDebugPrivilege                  = $Admins
    SeTakeOwnershipPrivilege          = $Admins
    SeLoadDriverPrivilege             = $Admins
    SeCreateSymbolicLinkPrivilege     = $Admins
    SeImpersonatePrivilege            = "$Admins,*S-1-5-19,*S-1-5-20,*S-1-5-6"            # + LOCAL SERVICE, NETWORK SERVICE, SERVICE
    SeSecurityPrivilege               = $Admins
    SeBackupPrivilege                 = "$Admins,*S-1-5-32-551"
}

$InfPath = Join-Path $env:TEMP 'secpol_hardening.inf'
$DbPath  = Join-Path $env:TEMP 'secpol_hardening.sdb'

$inf  = '[Unicode]', 'Unicode=yes', '[Version]', 'signature="$CHICAGO$"', 'Revision=1', '[System Access]'
$inf += $AccountPolicy.GetEnumerator()   | ForEach-Object { "$($_.Key) = $($_.Value)" }
$inf += '[Privilege Rights]'
$inf += $PrivilegeRights.GetEnumerator() | ForEach-Object { "$($_.Key) = $($_.Value)" }

Invoke-Step { $inf | Set-Content -Path $InfPath -Encoding Unicode } "Write $InfPath"
Invoke-Step { secedit /configure /db $DbPath /cfg $InfPath /areas SECURITYPOLICY USER_RIGHTS /quiet } `
            "secedit /configure /db $DbPath /cfg $InfPath /areas SECURITYPOLICY USER_RIGHTS /quiet"
Remove-Item $InfPath, $DbPath -Force -ErrorAction SilentlyContinue

Invoke-Step { gpupdate /force }

if ($Failures -gt 0) {
    Write-Host "[!] Completed with $Failures error(s). See $ErrorLog" -ForegroundColor Yellow
} else {
    Write-Host "[+] Local Security Policy hardening applied successfully." -ForegroundColor Green
}