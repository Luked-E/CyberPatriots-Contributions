# Requires Administrator privileges
# Run as Administrator in PowerShell

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be executed in an elevated PowerShell prompt (Run as Administrator)."
    exit
}

Write-Host "Configuring Core Operating System Hardening Policies..." -ForegroundColor Cyan

# ==============================================================================
# 1. ACCOUNTS POLICY
# ==============================================================================
Write-Host "Configuring Accounts..." -ForegroundColor Yellow

# Rename Administrator & Guest Accounts
net user Administrator /active:no 2>$null
net user Administrator Saxon 2>$null  # Rename Administrator to Saxon
net user Saxon /active:no             # Ensure disabled

net user Guest /active:no 2>$null
net user Guest NotSaxon 2>$null       # Rename Guest to NotSaxon
net user NotSaxon /active:no          # Ensure disabled

# Limit local account use of blank passwords to console logon only (0 = Enabled, 1 = Disabled)
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "LimitBlankPasswordUse" -Value 1 -Type DWord


# ==============================================================================
# 2. AUDIT POLICY
# ==============================================================================
Write-Host "Configuring Audit Policies..." -ForegroundColor Yellow

# Shut down system immediately if unable to log security audits (1 = Enabled)
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "CrashOnAuditFail" -Value 1 -Type DWord


# ==============================================================================
# 3. DEVICES POLICY
# ==============================================================================
Write-Host "Configuring Devices Policies..." -ForegroundColor Yellow

# Allow undock without having to log on (0 = Disabled)
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "UndockWithoutLogon" -Value "0" -Type String

# Allowed to format and eject removable media (0 = Administrators)
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "AllocateDASD" -Value "0" -Type String

# Prevent users from installing printer drivers (1 = Enabled)
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Print\Providers\LanMan Print Services\Servers" -Name "AddPrinterDrivers" -Value 1 -Type DWord

# Restrict CD-ROM access to locally logged-on user only (1 = Enabled)
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "AllocateCDRoms" -Value "1" -Type String

# Restrict floppy access to locally logged-on user only (1 = Enabled)
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "AllocateFloppies" -Value "1" -Type String


# ==============================================================================
# 4. INTERACTIVE LOGON POLICY
# ==============================================================================
Write-Host "Configuring Interactive Logon Policies..." -ForegroundColor Yellow

# Do not display last user name (1 = Enabled)
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "DontDisplayLastUserName" -Value 1 -Type DWord

# Do not require CTRL+ALT+DEL (0 = Require CTRL+ALT+DEL / Disabled)
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "DisableCAD" -Value 0 -Type DWord

# Legal Warning Title and Text
$BannerTitle = "WARNING: Legal Notice"
$BannerText  = "Authorized Use Only. All activities are monitored and logged."

Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "LegalNoticeCaption" -Value $BannerTitle -Type String
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "LegalNoticeText" -Value $BannerText -Type String

# Number of previous logons to cache (0 = Disabled)
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "CachedLogonsCount" -Value "0" -Type String

# Prompt user to change password before expiration (14 Days)
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "PasswordExpiryWarning" -Value 14 -Type DWord

# Display user information when session is locked (3 = Do not display user information)
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "DontDisplayLockedUserId" -Value 3 -Type DWord


# ==============================================================================
# 5. RECOVERY CONSOLE & SHUTDOWN POLICY
# ==============================================================================
Write-Host "Configuring Recovery Console & Shutdown Policies..." -ForegroundColor Yellow

# Recovery console: Allow automatic administrative logon (0 = Disabled)
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Setup\RecoveryConsole" -Name "SecurityLevel" -Value 0 -Type DWord

# Recovery console: Allow floppy copy and access to all drives (0 = Disabled)
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Setup\RecoveryConsole" -Name "SetCommand" -Value 0 -Type DWord

# Shutdown: Allow system to be shut down without having to log on (0 = Disabled)
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ShutdownWithoutLogon" -Value 0 -Type DWord

# Shutdown: Clear virtual memory pagefile (1 = Enabled)
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "ClearPageFileAtShutdown" -Value 1 -Type DWord


# ==============================================================================
# 6. USER ACCOUNT CONTROL (UAC) POLICY
# ==============================================================================
Write-Host "Configuring User Account Control (UAC) Policies..." -ForegroundColor Yellow

# Enable Admin Approval Mode for Built-in Administrator (1 = Enabled)
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "FilterAdministratorToken" -Value 1 -Type DWord

# Allow UIAccess applications to prompt without secure desktop (0 = Disabled)
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableUIADesktopToggle" -Value 0 -Type DWord

# Behavior of elevation prompt for administrators (2 = Prompt for consent on secure desktop)
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 2 -Type DWord

# Behavior of elevation prompt for standard users (1 = Automatically deny elevation requests)
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorUser" -Value 1 -Type DWord

# Detect application installations and prompt for elevation (1 = Enabled)
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableInstallerDetection" -Value 1 -Type DWord

# Only elevate executables that are signed and validated (1 = Enabled)
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ValidateAdminCodeSignatures" -Value 1 -Type DWord

# Run all administrators in Admin Approval Mode (1 = Enabled)
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 1 -Type DWord

# Switch to the secure desktop when prompting for elevation (1 = Enabled)
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "PromptOnSecureDesktop" -Value 1 -Type DWord


# ==============================================================================
# 7. FORCE POLICY UPDATE
# ==============================================================================
Write-Host "Refreshing System Group Policy..." -ForegroundColor Yellow
gpupdate /force | Out-Null

Write-Host "Core Operating System Hardening complete! A system reboot is recommended." -ForegroundColor Green