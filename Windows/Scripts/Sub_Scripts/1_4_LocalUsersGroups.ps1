[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$WindowsVersion = "Windows 11"
)

$ErrorActionPreference = 'Stop'
$ErrorLog   = Join-Path (Get-Location) 'errors.log'
$ScriptName = Split-Path $PSCommandPath -Leaf

# Runs one action; on failure logs script name, command text and error to errors.log.
function Step([string]$Label, [scriptblock]$Action) {
    try {
        & $Action
        Write-Host "[+] $Label" -ForegroundColor Green
    } catch {
        Write-Host "[-] $Label failed: $($_.Exception.Message)" -ForegroundColor Red
        Add-Content -Path $ErrorLog -Value "[$(Get-Date -Format s)] $ScriptName | Command: $($Action.ToString().Trim()) | Error: $($_.Exception.Message)"
    }
}

Write-Host "[*] Configuring local users and groups for $WindowsVersion..." -ForegroundColor Cyan

# 1 & 3. Disable Guest (RID 501), DefaultAccount (503) and WDAGUtilityAccount (504).
foreach ($u in Get-LocalUser | Where-Object { $_.SID.Value -match '-(501|503|504)$' }) {
    Step "Disable built-in account $($u.Name)" { Disable-LocalUser -Name $u.Name }
}

# 5. Password expiry enforced on every account except DefaultAccount/WDAGUtilityAccount.
foreach ($u in Get-LocalUser | Where-Object { $_.SID.Value -notmatch '-(503|504)$' }) {
    Step "Enforce password expiry for $($u.Name)" { Set-LocalUser -Name $u.Name -PasswordNeverExpires $false }
}

# 4. Report (read-only) members of sensitive groups, and 5. audit all local users.
foreach ($grp in "Administrators", "Backup Operators", "Remote Management Users", "Distributed COM Users",
                 "Event Log Readers", "Performance Log Users", "Performance Monitor Users", "Cryptographic Operators") {
    Step "List members of $grp" {
        Write-Host "=== Members of $grp ===" -ForegroundColor Cyan
        Get-LocalGroupMember -Group $grp | Select-Object Name, PrincipalSource | Format-Table -AutoSize | Out-Host
    }
}

Get-LocalUser | Select-Object Name, Enabled, PasswordRequired, PasswordLastSet, PasswordNeverExpires, UserMayChangePassword, LastLogon |
    Sort-Object Enabled -Descending | Format-Table -AutoSize

Write-Host "[+] Local users and groups configured. Errors (if any) logged to $ErrorLog" -ForegroundColor Green