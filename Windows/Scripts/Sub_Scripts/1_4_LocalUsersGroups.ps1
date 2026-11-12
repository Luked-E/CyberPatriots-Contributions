[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$WindowsVersion = "Windows 11"
)

$ErrorActionPreference = 'Stop'
$ThisScript = $MyInvocation.MyCommand.Name

# ---------------------------------------------------------------------------
# Load EngineUtils from the orchestrator root (manifest preferred, .psm1 fallback)
# ---------------------------------------------------------------------------
$ParentDir = Split-Path -Parent $PSScriptRoot
$ModulePath = @('EngineUtils.psd1', 'EngineUtils.psm1') |
    ForEach-Object { Join-Path $ParentDir $_ } |
    Where-Object { Test-Path -LiteralPath $_ } |
    Select-Object -First 1

if (-not $ModulePath) {
    throw "EngineUtils.psd1 / EngineUtils.psm1 not found in $ParentDir"
}

# -ArgumentList feeds the module's param() block so log lines show the real Windows version
Import-Module -Name $ModulePath -Force -ArgumentList $WindowsVersion
Assert-AdminPrivileges

Write-Host "[*] Configuring local users and groups for $WindowsVersion..." -ForegroundColor Cyan
# ---------------------------------------------------------------------------
# Authorized accounts & Player Validation (Parsed dynamically from README)[cite: 1, 2]
# ---------------------------------------------------------------------------
$Administrators = @("Administrator")   # Authorized administrators baseline
$StandardUsers  = @()                  # Authorized standard users
$PlayerName     = $null                # Designated player account from (you) tag

$ReadmePath = Join-Path $ParentDir "users.txt"

if ($ReadmePath -and (Test-Path -LiteralPath $ReadmePath)) {
    Write-Host "[*] Parsing authorized accounts and player tag from: $ReadmePath" -ForegroundColor Cyan
    try {
        $FileContent = Get-Content -LiteralPath $ReadmePath -ErrorAction Stop
        $Section = $null
        $ParsedAdmins = @()
        $ParsedUsers = @()

        foreach ($line in $FileContent) {
            $trimmed = $line.Trim()

            # Identify section headers
            if ($trimmed -match '^Authorized Administrators:') {
                $Section = 'Admins'
                continue
            }
            elseif ($trimmed -match '^Authorized Users:') {
                $Section = 'Users'
                continue
            }
            elseif ($trimmed -match '^Competition Guidelines' -or $trimmed -match '^---') {
                $Section = $null
                continue
            }

            # Skip empty lines or password lines
            if (-not $trimmed) { continue }
            if ($trimmed -match '^password\s*:') { continue }

            # Check if this line designates the player account with '(you)'[cite: 2]
            if ($trimmed -match '\(you\)') {
                $PlayerName = ($trimmed -replace '\s*\(.*\)\s*$', '').Trim()
            }

            # Extract clean username (removes annotations)
            $userName = ($trimmed -replace '\s*\(.*\)\s*$', '').Trim()

            if ($userName) {
                if ($Section -eq 'Admins') {
                    if ($ParsedAdmins -notcontains $userName) {
                        $ParsedAdmins += $userName
                    }
                }
                elseif ($Section -eq 'Users') {
                    if ($ParsedUsers -notcontains $userName) {
                        $ParsedUsers += $userName
                    }
                }
            }
        }

        if ($ParsedAdmins.Count -gt 0) {
            $Administrators = @($Administrators + $ParsedAdmins) | Select-Object -Unique
        }
        if ($ParsedUsers.Count -gt 0) {
            $StandardUsers = @($ParsedUsers) | Select-Object -Unique
        }

        Write-Host "[+] Loaded $( $ParsedAdmins.Count ) authorized administrator(s) and $( $ParsedUsers.Count ) standard user(s) from README." -ForegroundColor Green
    } catch {
        Write-WarningLog -Message "Failed to parse README file at '$ReadmePath': $($_.Exception.Message)" -ScriptName $ThisScript
        Write-Host "[-] Failed to parse README file. Using default/fallback user lists." -ForegroundColor Yellow
    }
} else {
    Write-Host "[*] No authorized users text file found. Using default script lists." -ForegroundColor Yellow
}

# ---------------------------------------------------------------------------
# Player Validation Check: Abort if current user doesn't match the (you) tag[cite: 2]
# ---------------------------------------------------------------------------
$CurrentUser = $env:USERNAME

# ---------------------------------------------------------------------------
# Excerpt: Print Current User and Extracted User Lists
# ---------------------------------------------------------------------------
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "             USER file SUMMARY                   " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

Write-Host "Current Logged-In User : " -NoNewline; Write-Host "$CurrentUser" -ForegroundColor Yellow
if ($PlayerName) {
    Write-Host "Identified Player Tag  : " -NoNewline; Write-Host "$PlayerName" -ForegroundColor Green
}

Write-Host "`nAuthorized Administrators ($( $Administrators.Count )): " -ForegroundColor Cyan
foreach ($admin in $Administrators) {
    Write-Host "  [Admin] $admin" -ForegroundColor White
}

Write-Host "`nAuthorized Standard Users ($( $StandardUsers.Count )): " -ForegroundColor Cyan
if ($StandardUsers.Count -gt 0) {
    foreach ($user in $StandardUsers) {
        Write-Host "  [User]  $user" -ForegroundColor White
    }
} else {
    Write-Host "  (None)" -ForegroundColor DarkGray
}
Write-Host "==================================================" -ForegroundColor Cyan

if ($PlayerName -and ($CurrentUser -ne $PlayerName)) {
    $AbortMessage = "ABORT: Current logged-in user ('$CurrentUser') does not match the designated player account ('$PlayerName') found in the README[cite: 2]."
    Write-ErrorLog -Message $AbortMessage -ScriptName $ThisScript
    throw $AbortMessage
}

$AuthorizedUsers = $Administrators + $StandardUsers + $CurrentUser
$AuthorizedAdmins = $Administrators + $CurrentUser

# Built-in accounts are matched by SID so renamed accounts are still recognized:
# 500 = Administrator, 501 = Guest, 503 = DefaultAccount, 504 = WDAGUtilityAccount
$BuiltInSidPattern = '-(500|501|503|504)$'
$AdminGroupSid     = 'S-1-5-32-544'

$Findings = 0

Write-Host "[*] Current user '$CurrentUser' is always treated as authorized." -ForegroundColor DarkGray

# ---------------------------------------------------------------------------
# 1. Unauthorized user accounts (audit by default, delete with -RemoveUnauthorizedUsers)
# ---------------------------------------------------------------------------
foreach ($u in Get-LocalUser) {
    if ($u.SID.Value -match $BuiltInSidPattern) { continue }
    if ($AuthorizedUsers -contains $u.Name) { continue }

    Invoke-Step "Delete unauthorized user account $($u.Name)" { Remove-LocalUser -SID $u.SID }
}

# ---------------------------------------------------------------------------
# 2. Disable built-in Guest, DefaultAccount and WDAGUtilityAccount
# ---------------------------------------------------------------------------
foreach ($u in Get-LocalUser | Where-Object { $_.SID.Value -match '-(501|503|504)$' -and $_.Enabled }) {
    Invoke-Step "Disable built-in account $($u.Name)" { Disable-LocalUser -SID $u.SID }
}

# ---------------------------------------------------------------------------
# 3. Administrators group: ensure authorized admins are members, flag/remove the rest
# ---------------------------------------------------------------------------
$AdminMembers = $null
try {
    $AdminMembers = @(Get-LocalGroupMember -SID $AdminGroupSid)
} catch {
    Write-WarningLog -Message "Could not enumerate the Administrators group: $($_.Exception.Message)" -ScriptName $ThisScript
}

if ($null -ne $AdminMembers) {
    $AdminMemberNames = @($AdminMembers | ForEach-Object { $_.Name -replace '^.*\\' })

    foreach ($admin in $Administrators) {
        if ($AdminMemberNames -contains $admin) { continue }
        if (Get-LocalUser -Name $admin -ErrorAction SilentlyContinue) {
            Invoke-Step "Add $admin to Administrators group" {
                Add-LocalGroupMember -SID $AdminGroupSid -Member $admin
            }
        }
    }

    foreach ($m in $AdminMembers) {
        $memberName = $m.Name -replace '^.*\\'

        if ($m.PrincipalSource -ne 'Local' -or $m.ObjectClass -ne 'User') {
            Write-Host "[*] Skipping non-local or non-user Administrators member: $($m.Name)" -ForegroundColor DarkGray
            continue
        }
        if ($m.SID.Value -match '-500$') { continue }
        if ($AuthorizedAdmins -contains $memberName) { continue }

        Invoke-Step "Remove $memberName from Administrators group" {
            Remove-LocalGroupMember -SID $AdminGroupSid -Member $m
        }
        # } else {
        #     $Findings++
        #     Write-WarningLog -Message "Unauthorized Administrators member found: $($m.Name) (use -RemoveUnauthorizedAdmins to remove)" -ScriptName $ThisScript
        # }
    }
}

# ---------------------------------------------------------------------------
# 4. Password policy on enabled, non-player accounts (no passwords are changed here)
# ---------------------------------------------------------------------------
foreach ($u in Get-LocalUser | Where-Object { $_.Enabled -and $_.SID.Value -notmatch '-(501|503|504)$' }) {
    if ($CurrentUser -contains $u.Name) {
        Write-Host "[*] Skipping password policy changes for Player account: $($u.Name)" -ForegroundColor DarkGray
        continue
    }

    # Get-LocalUser has no PasswordNeverExpires property; a null PasswordExpires means "never expires"
    if ($null -eq $u.PasswordExpires) {
        Invoke-Step "Enforce password expiry for $($u.Name)" { Set-LocalUser -SID $u.SID -PasswordNeverExpires $false }
    }

    if (-not $u.PasswordRequired) {
        Invoke-Step "Require a password for $($u.Name)" { & net.exe user $u.Name /passwordreq:yes }
    }
}

# ---------------------------------------------------------------------------
# 5. Set default password for all users except the player account
# ---------------------------------------------------------------------------
foreach ($u in Get-LocalUser | Where-Object { $_.Enabled -and $_.SID.Value -notmatch '-(501|503|504)$' }) {
    if (($u.Name -eq $PlayerName) -or ($u.Name -eq $CurrentUser)) {
        Write-Host "[*] Skipping password change for Player account: $($u.Name)" -ForegroundColor DarkGray
        continue
    }

    Invoke-Step "Change password for user $($u.Name)" {
        $SecurePassword = "C1sc0!314159@SVT" | ConvertTo-SecureString -AsPlainText -Force
        Set-LocalUser -SID $u.SID -Password $SecurePassword
    }
}

# ---------------------------------------------------------------------------
# 6. Report members of sensitive groups and all local users
#    (logged with Write-WarningLog so they land in the log file for review)
# ---------------------------------------------------------------------------
$SensitiveGroups = @(
    "Administrators", "Backup Operators", "Remote Desktop Users", "Remote Management Users",
    "Power Users", "Account Operators", "Server Operators", "Print Operators", "Replicator",
    "Network Configuration Operators", "Hyper-V Administrators", "Distributed COM Users",
    "Event Log Readers", "Performance Log Users", "Performance Monitor Users", "Cryptographic Operators"
)

foreach ($grp in $SensitiveGroups) {
    if (Get-LocalGroup -Name $grp -ErrorAction SilentlyContinue) {
        Invoke-Step "List members of $grp" {
            $memberList = @()
            try {
                $memberList = @(Get-LocalGroupMember -Group $grp | ForEach-Object { "{0} ({1})" -f $_.Name, $_.PrincipalSource })
            } catch {
                # Get-LocalGroupMember fails on orphaned SIDs in Windows PowerShell 5.1; fall back to net.exe
                $lines = @(& net.exe localgroup $grp)
                $sep = 0..($lines.Count - 1) | Where-Object { $lines[$_] -match '^-{5,}' } | Select-Object -First 1
                if ($null -eq $sep) { throw "Could not parse 'net localgroup' output for group '$grp'" }
                $memberList = @($lines[($sep + 1)..($lines.Count - 1)] |
                    Where-Object { $_.Trim() } |
                    Select-Object -SkipLast 1 |
                    ForEach-Object { $_.Trim() })
            }

            if ($memberList.Count -gt 0) {
                Write-WarningLog -Message "Members of ${grp}: $($memberList -join '; ')" -ScriptName $ThisScript
            } else {
                Write-Host "[*] Group '$grp' has no members." -ForegroundColor DarkGray
            }
        }
    } else {
        Write-Host "[*] Skipping group '$grp' (does not exist on this system)." -ForegroundColor DarkGray
    }
}

$FormatDate = { param($d) if ($d) { $d.ToString('yyyy-MM-dd HH:mm') } else { 'never' } }

foreach ($u in Get-LocalUser | Sort-Object Enabled -Descending) {
    Write-WarningLog -Message ("User {0} | Enabled={1} | PasswordRequired={2} | PasswordLastSet={3} | PasswordExpires={4} | UserMayChangePassword={5} | LastLogon={6}" -f `
        $u.Name, $u.Enabled, $u.PasswordRequired, (& $FormatDate $u.PasswordLastSet), (& $FormatDate $u.PasswordExpires), $u.UserMayChangePassword, (& $FormatDate $u.LastLogon)) -ScriptName $ThisScript
}

if ($Findings -gt 0) {
    Write-WarningLog -Message "$Findings unauthorized item(s) found and NOT changed. Review the warnings above, then re-run with -RemoveUnauthorizedUsers and/or -RemoveUnauthorizedAdmins." -ScriptName $ThisScript
}

Write-Host "[+] Local users and groups pass complete. Failed steps are marked [-] and logged to the Logs directory." -ForegroundColor Green
