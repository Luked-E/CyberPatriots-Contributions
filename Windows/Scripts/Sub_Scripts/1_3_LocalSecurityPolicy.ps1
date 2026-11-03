[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$WindowsVersion = "Windows 11"
)

$ParentDir = [System.IO.Directory]::GetParent($PSScriptRoot).FullName
Import-Module -Name "$ParentDir\EngineUtils.psd1" -Force
Assert-AdminPrivileges

$ErrorActionPreference = 'Stop'

Write-Host "[*] Applying Local Security Policy hardening for $WindowsVersion..." -ForegroundColor Cyan

# ---------------------------------------------------------------------------
# 1. Registry-backed Security Options (what secpol.msc writes under the hood)
# ---------------------------------------------------------------------------
$Sys  = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
$Win  = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
$Lsa  = 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa'
$Svc  = 'HKLM:\SYSTEM\CurrentControlSet\Services'
$SesM = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'

$RegistrySettings = @"
Path|Name|Type|Value
$Lsa|LimitBlankPasswordUse|DWord|1
$Lsa|CrashOnAuditFail|DWord|1
$Lsa|SCENoApplyLegacyAuditPolicy|DWord|1
$Lsa|RestrictAnonymous|DWord|1
$Lsa|RestrictAnonymousSAM|DWord|1
$Lsa|EveryoneIncludesAnonymous|DWord|0
$Lsa|DisableDomainCreds|DWord|1
$Lsa|NoLMHash|DWord|1
$Lsa|LmCompatibilityLevel|DWord|5
$Lsa|ForceGuest|DWord|0
$Lsa\FipsAlgorithmPolicy|Enabled|DWord|0
$Lsa\MSV1_0|AllowNullSessionFallback|DWord|0
$Lsa\MSV1_0|NTLMMinClientSec|DWord|537395200
$Lsa\MSV1_0|NTLMMinServerSec|DWord|537395200
$Lsa\MSV1_0|RestrictReceivingNTLMTraffic|DWord|2
$Lsa\pku2u|AllowOnlineID|DWord|0
$Svc\Netlogon\Parameters|RequireSignOrSeal|DWord|1
$Svc\Netlogon\Parameters|SealSecureChannel|DWord|1
$Svc\Netlogon\Parameters|SignSecureChannel|DWord|1
$Svc\Netlogon\Parameters|RequireStrongKey|DWord|1
$Svc\Netlogon\Parameters|DisablePasswordChange|DWord|0
$Svc\Netlogon\Parameters|MaximumPasswordAge|DWord|30
$Svc\Netlogon\Parameters|RestrictNTLMInDomain|DWord|7
$Svc\LanmanServer\Parameters|RequireSecuritySignature|DWord|1
$Svc\LanmanServer\Parameters|EnableSecuritySignature|DWord|1
$Svc\LanmanServer\Parameters|EnableForcedLogoff|DWord|1
$Svc\LanmanServer\Parameters|RestrictNullSessAccess|DWord|1
$Svc\LanmanWorkstation\Parameters|RequireSecuritySignature|DWord|1
$Svc\LanmanWorkstation\Parameters|EnableSecuritySignature|DWord|1
$Svc\LanmanWorkstation\Parameters|EnablePlainTextPassword|DWord|0
HKLM:\SYSTEM\CurrentControlSet\Control\Print\Providers\LanMan Print Services\Servers|AddPrinterDrivers|DWord|1
$SesM\Memory Management|ClearPageFileAtShutdown|DWord|1
$SesM\Kernel|ObCaseInsensitive|DWord|1
$SesM|ProtectionMode|DWord|1
HKLM:\SOFTWARE\Policies\Microsoft\Windows\Safer\CodeIdentifiers|AuthenticodeEnabled|DWord|0
HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Setup\RecoveryConsole|SecurityLevel|DWord|0
HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Setup\RecoveryConsole|SetCommand|DWord|0
$Win|AllocateDASD|String|0
$Win|AllocateCDRoms|String|1
$Win|AllocateFloppies|String|1
$Win|CachedLogonsCount|String|0
$Win|PasswordExpiryWarning|DWord|14
$Win|ForceUnlockLogon|DWord|0
$Win|ScRemoveOption|String|0
$Sys|UndockWithoutLogon|DWord|0
$Sys|DontDisplayLastUserName|DWord|1
$Sys|DisableCAD|DWord|0
$Sys|LegalNoticeText|String|Authorized Use Only. All activities are monitored and logged.
$Sys|LegalNoticeCaption|String|WARNING: Legal Notice
$Sys|DontDisplayLockedUserId|DWord|3
$Sys|InactivityTimeoutSecs|DWord|300
$Sys|MaxDevicePasswordFailedAttempts|DWord|10
$Sys|ScForceOption|DWord|0
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
$Sys|EnableVirtualization|DWord|1
"@ | ConvertFrom-Csv -Delimiter '|'

foreach ($s in $RegistrySettings) {
    Set-RegValue -Path $s.Path -Name $s.Name -Value $s.Value -Type $s.Type
}

# Multi-string values that must exist but be EMPTY ("Enabled" with a blank string box).
# Registry.SetValue creates the key if it is missing and accepts an empty REG_MULTI_SZ.
$EmptyMultiStrings = @(
    @{ Key = 'SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters';              Name = 'NullSessionPipes'  },  # Named Pipes accessible anonymously
    @{ Key = 'SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters';              Name = 'NullSessionShares' },  # Shares accessible anonymously
    @{ Key = 'SYSTEM\CurrentControlSet\Control\SecurePipeServers\Winreg\AllowedExactPaths'; Name = 'Machine'      },  # Remotely accessible registry paths
    @{ Key = 'SYSTEM\CurrentControlSet\Control\SecurePipeServers\Winreg\AllowedPaths';      Name = 'Machine'      }   # ...and sub-paths
)
foreach ($m in $EmptyMultiStrings) {
    Invoke-Step -Command "Set empty REG_MULTI_SZ HKLM\$($m.Key)\$($m.Name)" -Action {
        [Microsoft.Win32.Registry]::SetValue("HKEY_LOCAL_MACHINE\$($m.Key)", $m.Name, [string[]]@(),
            [Microsoft.Win32.RegistryValueKind]::MultiString)
    }
}

# ---------------------------------------------------------------------------
# 2. Audit policy: Success + Failure on every category/subcategory
#    (covers both the legacy Audit Policy and Advanced Audit Policy sections;
#     each of the nine categories is set explicitly so failures are logged per category;
#     Global Object Access Auditing is intentionally left untouched)
# ---------------------------------------------------------------------------
$AuditCategories = @(
    'Account Logon', 'Account Management', 'Detailed Tracking', 'DS Access', 'Logon/Logoff',
    'Object Access', 'Policy Change', 'Privilege Use', 'System'
)
foreach ($cat in $AuditCategories) {
    Invoke-Step -Command "auditpol /set /category:`"$cat`" /success:enable /failure:enable" -Action {
        auditpol /set "/category:$cat" /success:enable /failure:enable
    }
}

# ---------------------------------------------------------------------------
# 3. Account policies, account status, and User Rights via one secedit import
# ---------------------------------------------------------------------------
# Only disable the built-in Administrator if another enabled local admin exists.
$HasOtherAdmin = $false
Invoke-Step -Command "Check for another enabled local administrator" -Action {
    $script:HasOtherAdmin = [bool](
        Get-LocalGroupMember -SID 'S-1-5-32-544' |
            Where-Object { $_.ObjectClass -eq 'User' -and $_.SID.Value -notlike '*-500' } |
            ForEach-Object { Get-LocalUser -SID $_.SID -ErrorAction SilentlyContinue } |
            Where-Object Enabled)
}

if (-not $HasOtherAdmin) {
    Write-WarningLog -message "No other enabled local administrator found - leaving the built-in Administrator enabled."
}

# Resolve the local Guest account (RID 500 is Administrator, RID 501 is Guest) so it can be
# denied explicitly in addition to the built-in Guests group.
$GuestAcct = $null
Invoke-Step -Command "Resolve local Guest account SID" -Action {
    $g = Get-LocalUser -ErrorAction SilentlyContinue | Where-Object { $_.SID.Value -like '*-501' } | Select-Object -First 1
    if ($g) { $script:GuestAcct = "*$($g.SID.Value)" }
}

$AccountPolicy = [ordered]@{
    MinimumPasswordAge         = 3
    MaximumPasswordAge         = 30
    MinimumPasswordLength      = 14
    PasswordComplexity         = 1
    PasswordHistorySize        = 24
    ClearTextPassword          = 0
    LockoutBadCount            = 5
    LockoutDuration            = 30
    ResetLockoutCount          = 30
    EnableGuestAccount         = 0
    LSAAnonymousNameLookup     = 0       # Network access: Allow anonymous SID/Name translation = Disabled
    ForceLogoffWhenHourExpire  = 0       # Network security: Force logoff when logon hours expire = Disabled
}
if ($HasOtherAdmin) { $AccountPolicy['EnableAdminAccount'] = 0 }
# NOTE: "Rename administrator/guest account" is left at the defaults (Administrator / Guest);
#       renaming is optional per the checklist and is intentionally not forced here.

$Admins = '*S-1-5-32-544'
$Guests = '*S-1-5-32-546'
$DenyGuest = (@($Guests) + @($GuestAcct) | Where-Object { $_ }) -join ','   # Guests group + Guest account

$PrivilegeRights = [ordered]@{
    # --- Must be EMPTY (no user or group) ---
    SeTrustedCredManAccessPrivilege   = ''                                                # Access Credential Manager as a trusted caller
    SeTcbPrivilege                    = ''                                                # Act as part of the operating system
    SeMachineAccountPrivilege         = ''                                                # Add workstations to domain
    SeCreateTokenPrivilege            = ''                                                # Create a token object
    SeCreatePermanentPrivilege        = ''                                                # Create permanent shared objects
    SeEnableDelegationPrivilege       = ''                                                # Enable accounts to be trusted for delegation
    SeLockMemoryPrivilege             = ''                                                # Lock pages in memory
    SeRelabelPrivilege                = ''                                                # Modify an object label
    SeSyncAgentPrivilege              = ''                                                # Synchronize directory service data

    # --- Logon rights ---
    SeNetworkLogonRight               = "$Admins,*S-1-5-11"                               # Administrators, Authenticated Users
    SeInteractiveLogonRight           = "$Admins,*S-1-5-11,*S-1-5-32-545"                 # Administrators, Authenticated Users (+Users so console logon can never lock out)
    SeRemoteInteractiveLogonRight     = "$Admins,*S-1-5-32-555"                           # Administrators, Remote Desktop Users
    SeBatchLogonRight                 = "$Admins,*S-1-5-32-551"                           # Administrators, Backup Operators
    SeServiceLogonRight               = '*S-1-5-18,*S-1-5-19,*S-1-5-20,*S-1-5-80-0'       # SYSTEM, LOCAL/NETWORK SERVICE, NT SERVICE\ALL SERVICES (needed so services keep starting)

    # --- Explicit denies ---
    SeDenyNetworkLogonRight           = "*S-1-5-7,$DenyGuest"                             # ANONYMOUS LOGON, Guest(s)
    SeDenyInteractiveLogonRight       = $DenyGuest
    SeDenyRemoteInteractiveLogonRight = "$DenyGuest,*S-1-5-7"                             # Guest(s), ANONYMOUS LOGON
    SeDenyBatchLogonRight             = $DenyGuest
    SeDenyServiceLogonRight           = $DenyGuest

    # --- Privileges ---
    SeIncreaseQuotaPrivilege          = "$Admins,*S-1-5-19,*S-1-5-20"                     # Adjust memory quotas: Admins, LOCAL SERVICE, NETWORK SERVICE
    SeBackupPrivilege                 = "$Admins,*S-1-5-32-551"                           # Administrators, Backup Operators
    SeChangeNotifyPrivilege           = "$Admins,*S-1-1-0,*S-1-5-32-545,*S-1-5-19,*S-1-5-20"  # Bypass traverse checking: Admins, Everyone, Users (+ service identities)
    SeSystemtimePrivilege             = "$Admins,*S-1-5-19"                               # Change the system time: Admins, LOCAL SERVICE
    SeTimeZonePrivilege               = "$Admins,*S-1-5-19"                               # Change the time zone: Admins, LOCAL SERVICE
    SeCreatePagefilePrivilege         = $Admins
    SeCreateGlobalPrivilege           = "$Admins,*S-1-5-19,*S-1-5-20,*S-1-5-6"            # Admins, LOCAL SERVICE, NETWORK SERVICE, SERVICE
    SeCreateSymbolicLinkPrivilege     = $Admins
    SeDebugPrivilege                  = $Admins
    SeRemoteShutdownPrivilege         = $Admins
    SeAuditPrivilege                  = '*S-1-5-19,*S-1-5-20'                             # Generate security audits: LOCAL SERVICE, NETWORK SERVICE
    SeImpersonatePrivilege            = "$Admins,*S-1-5-19,*S-1-5-20,*S-1-5-6"            # Admins, LOCAL SERVICE, NETWORK SERVICE, SERVICE
    SeIncreaseWorkingSetPrivilege     = "$Admins,*S-1-5-19"                               # Admins, LOCAL SERVICE
    SeIncreaseBasePriorityPrivilege   = $Admins                                           # Removes Window Manager Group
    SeLoadDriverPrivilege             = $Admins
    SeSecurityPrivilege               = $Admins                                           # Manage auditing and security log
    SeSystemEnvironmentPrivilege      = $Admins                                           # Modify firmware environment values
    SeDelegateSessionUserImpersonatePrivilege = $Admins                                   # Obtain impersonation token for another user in same session
    SeManageVolumePrivilege           = $Admins                                           # Perform volume maintenance tasks
    SeProfileSingleProcessPrivilege   = $Admins
    SeSystemProfilePrivilege          = "$Admins,*S-1-5-80-3139157870-2983391045-3678747466-658725712-1809340420"  # Admins, NT SERVICE\WdiServiceHost
    SeUndockPrivilege                 = $Admins                                           # Remove computer from docking station
    SeAssignPrimaryTokenPrivilege     = '*S-1-5-19,*S-1-5-20'                             # Replace a process level token: LOCAL SERVICE, NETWORK SERVICE
    SeRestorePrivilege                = $Admins
    SeShutdownPrivilege               = "$Admins,*S-1-5-32-551"                           # Administrators, Backup Operators
    SeTakeOwnershipPrivilege          = $Admins
}

$InfPath = Join-Path $env:TEMP 'secpol_hardening.inf'
$DbPath  = Join-Path $env:TEMP 'secpol_hardening.sdb'

$inf  = '[Unicode]', 'Unicode=yes', '[Version]', 'signature="$CHICAGO$"', 'Revision=1', '[System Access]'
$inf += $AccountPolicy.GetEnumerator()   | ForEach-Object { "$($_.Key) = $($_.Value)" }
$inf += '[Privilege Rights]'
$inf += $PrivilegeRights.GetEnumerator() | ForEach-Object { "$($_.Key) = $($_.Value)" }

Invoke-Step -Command "Write $InfPath" -Action { $inf | Set-Content -Path $InfPath -Encoding Unicode }
Invoke-Step -Command "secedit /configure /db $DbPath /cfg $InfPath /areas SECURITYPOLICY USER_RIGHTS /quiet" -Action {
    secedit /configure /db $DbPath /cfg $InfPath /areas SECURITYPOLICY USER_RIGHTS /quiet
}
Remove-Item $InfPath, $DbPath -Force -ErrorAction SilentlyContinue

Invoke-Step -Command "gpupdate /force" -Action { gpupdate /force }

Write-Host "[+] Local Security Policy hardening complete. Check the Logs directory for any errors." -ForegroundColor Green