[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$WindowsVersion = "Windows 11",

    # Enables a Windows feature (irreversible once enabled), so it stays an option.
    [Parameter(Mandatory = $false)]
    [switch]$EnableRecycleBin
)

$ParentDir = [System.IO.Directory]::GetParent($PSScriptRoot).FullName
Import-Module -Name "$ParentDir\EngineUtils.psd1" -Force
Assert-AdminPrivileges

$ErrorActionPreference = 'Stop'

Write-Host "[*] Applying Active Directory hardening for $WindowsVersion..." -ForegroundColor Cyan

# Domain Controllers only (DomainRole 4 or 5). Windows 11 can never be a DC, so skip cleanly there.
if ((Get-CimInstance Win32_ComputerSystem).DomainRole -lt 4) {
    Write-Host "[!] This host is not a Domain Controller. Nothing to do." -ForegroundColor Yellow
    return
}

Add-Type -AssemblyName System.Web
function New-RandomPassword {
    ConvertTo-SecureString ([System.Web.Security.Membership]::GeneratePassword(30, 10)) -AsPlainText -Force
}

# --- Default Domain Policy: password and lockout policy ---
Invoke-Step 'Set domain password and lockout policy' {
    Set-ADDefaultDomainPasswordPolicy -Identity (Get-ADDomain).DNSRoot `
        -MinPasswordLength 14 -ComplexityEnabled $true -PasswordHistoryCount 24 `
        -LockoutThreshold 5 -LockoutDuration '00:30:00'
}

# --- Default Domain Controllers Policy: auditing (Success + Failure) ---
# Make advanced audit subcategories win over legacy GPO audit settings so they persist.
Set-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa' 'SCENoApplyLegacyAuditPolicy' 1
foreach ($target in '/category:Account Management', '/category:Logon/Logoff', '/subcategory:Directory Service Access') {
    Invoke-Step "Enable auditing $target" { auditpol /set $target /success:enable /failure:enable | Out-Null }
}

# --- AS-REP roasting: require Kerberos preauthentication on every account ---
Invoke-Step 'Require Kerberos preauthentication' {
    Get-ADUser -Filter 'DoesNotRequirePreAuth -eq $true' | Set-ADAccountControl -DoesNotRequirePreAuth $false
}

# --- Kerberoasting: strong random passwords on SPN accounts, and none in Domain Admins ---
$daSid = $null
try {
    $daSid = "$((Get-ADDomain).DomainSID)-512"
} catch {
    Write-WarningLog -Message "Resolve Domain Admins SID | $($_.Exception.Message)"
}

$spnAccounts = @()
try {
    $spnAccounts = @(Get-ADUser -Filter 'ServicePrincipalName -like "*"' | Where-Object SamAccountName -ne 'krbtgt')
} catch {
    Write-WarningLog -Message "List accounts with SPNs | $($_.Exception.Message)"
}

foreach ($account in $spnAccounts) {
    Invoke-Step "Harden SPN account $($account.SamAccountName)" {
        Set-ADAccountPassword -Identity $account -Reset -NewPassword (New-RandomPassword)
        Remove-ADGroupMember -Identity $daSid -Members $account -Confirm:$false
    }
}

# --- krbtgt: reset twice (wait for replication between resets only when other DCs exist) ---
$multiDc = $false
try {
    $multiDc = @(Get-ADDomainController -Filter *).Count -gt 1
} catch {
    Write-WarningLog -Message "List domain controllers | $($_.Exception.Message)"
}

foreach ($pass in 1..2) {
    Invoke-Step "Reset krbtgt password (pass $pass of 2)" {
        Set-ADAccountPassword -Identity krbtgt -Reset -NewPassword (New-RandomPassword)
    }
    if ($pass -eq 1 -and $multiDc) {
        Write-Host "[*] Waiting 15 minutes for replication before the second krbtgt reset..." -ForegroundColor Cyan
        Start-Sleep -Seconds 900
    }
}

# --- AD Recycle Bin (option) ---
if ($EnableRecycleBin) {
    Invoke-Step 'Enable AD Recycle Bin' {
        if (-not (Get-ADOptionalFeature -Filter "Name -eq 'Recycle Bin Feature'").EnabledScopes) {
            Enable-ADOptionalFeature 'Recycle Bin Feature' -Scope ForestOrConfigurationSet -Target (Get-ADForest).Name -Confirm:$false
        }
    }
}

Write-Host "[+] Active Directory hardening complete. Check the Logs directory for any failures." -ForegroundColor Green