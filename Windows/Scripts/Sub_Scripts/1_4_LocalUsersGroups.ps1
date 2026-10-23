[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$WindowsVersion = "Windows 11"
)

$ParentDir = [System.IO.Directory]::GetParent($PSScriptRoot).FullName
Import-Module -Name "$ParentDir\EngineUtils.psd1" -Force
Assert-AdminPrivileges

$ErrorActionPreference = 'Stop'

Write-Host "[*] Configuring local users and groups for $WindowsVersion..." -ForegroundColor Cyan

# 1 & 3. Disable Guest (RID 501), DefaultAccount (503) and WDAGUtilityAccount (504).
foreach ($u in Get-LocalUser | Where-Object { $_.SID.Value -match '-(501|503|504)$' }) {
    Invoke-Step "Disable built-in account $($u.Name)" { Disable-LocalUser -Name $u.Name }
}

# 5. Password expiry enforced on every account except DefaultAccount/WDAGUtilityAccount.
foreach ($u in Get-LocalUser | Where-Object { $_.SID.Value -notmatch '-(503|504)$' }) {
    Invoke-Step "Enforce password expiry for $($u.Name)" { Set-LocalUser -Name $u.Name -PasswordNeverExpires $false }
}

# 4. Report (read-only) members of sensitive groups, and 5. audit all local users.
foreach ($grp in "Administrators", "Backup Operators", "Remote Management Users", "Distributed COM Users",
                 "Event Log Readers", "Performance Log Users", "Performance Monitor Users", "Cryptographic Operators") {
    if (Get-LocalGroup -Name $grp -ErrorAction SilentlyContinue) {
        Invoke-Step "List members of $grp" {
            Write-Host "=== Members of $grp ===" -ForegroundColor Cyan
            Get-LocalGroupMember -Group $grp | Select-Object Name, PrincipalSource | Format-Table -AutoSize | Out-Host
        }
    } else {
        Write-Host "[*] Skipping group '$grp' (does not exist on this system)." -ForegroundColor DarkGray
    }
}

Get-LocalUser | Select-Object Name, Enabled, PasswordRequired, PasswordLastSet, PasswordNeverExpires, UserMayChangePassword, LastLogon |
    Sort-Object Enabled -Descending | Format-Table -AutoSize

Write-Host "[+] Local users and groups configured. Errors (if any) logged to the Logs directory." -ForegroundColor Green