[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$WindowsVersion = "Windows 11"
)

# --- Error log: errors are APPENDED to error.log (shared by all subscripts) ---
# Lives in the orchestrator root (parent of Sub_Scripts) when run from Sub_Scripts, otherwise next to this script.
$ScriptName = Split-Path -Leaf $PSCommandPath
$LogDir     = if ((Split-Path -Leaf $PSScriptRoot) -eq "Sub_Scripts") { Split-Path -Parent $PSScriptRoot } else { $PSScriptRoot }
$ErrorLogPath = Join-Path $LogDir "errors.log"
$script:Failures = 0
$ErrorActionPreference = 'Stop'

function Write-ErrorLog {
    param([Parameter(Mandatory)][string]$Message)
    $script:Failures++
    Write-Host "    [!] $Message" -ForegroundColor Red
    $line = "{0} [ERROR] [{1}] [{2}] {3}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $ScriptName, $WindowsVersion, $Message
    try {
        Add-Content -LiteralPath $ErrorLogPath -Value $line -Encoding UTF8 -ErrorAction Stop
    } catch {
        Write-Host "    [!] Could not write to $ErrorLogPath : $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Any unexpected terminating error is logged too, and the script keeps going.
trap {
    Write-ErrorLog "Unhandled error: $($_.Exception.Message) (line $($_.InvocationInfo.ScriptLineNumber))"
    continue
}

Write-Host "[*] Applying security hardening baseline for $WindowsVersion..." -ForegroundColor Cyan

# Creates the key if missing and writes a typed value; logs failures instead of hiding them.
function Set-RegValue {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)]$Value,
        [ValidateSet("DWord", "String")][string]$Type = "DWord"
    )
    try {
        if (-not (Test-Path -LiteralPath $Path)) {
            New-Item -Path $Path -Force -ErrorAction Stop | Out-Null
        }
        New-ItemProperty -LiteralPath $Path -Name $Name -Value $Value -PropertyType $Type -Force -ErrorAction Stop | Out-Null
    } catch {
        Write-ErrorLog "Failed to set $Path\$Name : $($_.Exception.Message)"
    }
}

# --- Pre-flight: must be elevated (HKLM, firewall, VSS, and restore points all require it) ---
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-ErrorLog "Script must be run as Administrator."
    exit 1
}

# 1. System Protection & Baseline Restore Point
#    Runs FIRST so the restore point captures the system before any changes below.
Write-Host "[*] Configuring System Protection and creating baseline restore point..." -ForegroundColor Yellow

# Windows throttles restore points to one per 24h by default; 0 removes the throttle.
Set-RegValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" `
             -Name "SystemRestorePointCreationFrequency" -Value 0 -Type DWord

try {
    if ($PSVersionTable.PSEdition -eq "Core") {
        # The System Restore cmdlets only exist in Windows PowerShell 5.1
        $out = & powershell.exe -NoProfile -Command "Enable-ComputerRestore -Drive 'C:\' -ErrorAction Stop; Checkpoint-Computer -Description 'CyberPatriot Baseline Clean' -RestorePointType 'MODIFY_SETTINGS' -ErrorAction Stop" 2>&1
        if ($LASTEXITCODE -ne 0) { throw "powershell.exe exited with code $LASTEXITCODE. $($out -join ' ')" }
    } else {
        Enable-ComputerRestore -Drive "C:\" -ErrorAction Stop
        Checkpoint-Computer -Description "CyberPatriot Baseline Clean" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
    }
} catch {
    Write-ErrorLog "Restore point failed: $($_.Exception.Message)"
}

$out = vssadmin resize shadowstorage /For=C: /On=C: /MaxSize=10% 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-ErrorLog "Could not set shadow storage limit (vssadmin exit code $LASTEXITCODE): $($out -join ' ')"
}

# 2. User Account Control (UAC) - Always notify on the secure desktop
Write-Host "[*] Configuring User Account Control (UAC)..." -ForegroundColor Yellow
$UacPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
Set-RegValue -Path $UacPath -Name "EnableLUA"                  -Value 1 -Type DWord
Set-RegValue -Path $UacPath -Name "ConsentPromptBehaviorAdmin" -Value 2 -Type DWord   # Prompt for consent on secure desktop
Set-RegValue -Path $UacPath -Name "ConsentPromptBehaviorUser"  -Value 0 -Type DWord   # Automatically deny elevation requests
Set-RegValue -Path $UacPath -Name "PromptOnSecureDesktop"      -Value 1 -Type DWord

# 3. Screen saver, 10-minute timeout, password on resume
#    Policy keys enforce the setting; the Control Panel\Desktop values keep the UI in sync.
#    A screen saver executable must be set or ScreenSaveActive has no effect.
#    NOTE: HKCU applies to the account running this script only.
Write-Host "[*] Configuring Screen Saver and Lockout Password..." -ForegroundColor Yellow
$DesktopPath       = "HKCU:\Control Panel\Desktop"
$DesktopPolicyPath = "HKCU:\Software\Policies\Microsoft\Windows\Control Panel\Desktop"
foreach ($p in @($DesktopPath, $DesktopPolicyPath)) {
    Set-RegValue -Path $p -Name "ScreenSaveActive"    -Value "1"            -Type String
    Set-RegValue -Path $p -Name "ScreenSaverIsSecure" -Value "1"            -Type String
    Set-RegValue -Path $p -Name "ScreenSaveTimeOut"   -Value "600"          -Type String
    Set-RegValue -Path $p -Name "SCRNSAVE.EXE"        -Value "scrnsave.scr" -Type String
}
# Machine inactivity limit (lock the machine after 600 seconds idle)
Set-RegValue -Path $UacPath -Name "InactivityTimeoutSecs" -Value 600 -Type DWord

# 4. File Explorer options (show hidden files, extensions, and protected OS files)
#    NOTE: HKCU applies to the current user; Explorer must be restarted/refreshed to show the change.
Write-Host "[*] Configuring File Explorer Visibility Options..." -ForegroundColor Yellow
$ExplorerPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
Set-RegValue -Path $ExplorerPath -Name "Hidden"          -Value 1 -Type DWord   # 1 = show hidden files
Set-RegValue -Path $ExplorerPath -Name "HideFileExt"     -Value 0 -Type DWord   # 0 = show file extensions
Set-RegValue -Path $ExplorerPath -Name "ShowSuperHidden" -Value 1 -Type DWord   # 1 = show protected OS files

# 5. Advanced Network Sharing - disable Network Discovery and File and Printer Sharing (public profile)
#    Rule groups are referenced by resource ID so this works on any display language.
Write-Host "[*] Hardening Advanced Network Sharing Settings..." -ForegroundColor Yellow
try {
    # Network Discovery
    Get-NetFirewallRule -Group "@FirewallAPI.dll,-32752" -ErrorAction Stop |
        Set-NetFirewallRule -Enabled False -ErrorAction Stop
} catch {
    Write-ErrorLog "Network Discovery firewall rules failed: $($_.Exception.Message)"
}
try {
    # File and Printer Sharing (only rules that apply to the Public profile)
    Get-NetFirewallRule -Group "@FirewallAPI.dll,-28502" -ErrorAction Stop |
        Where-Object { $_.Profile -match "Public|Any" } |
        Set-NetFirewallRule -Enabled False -ErrorAction Stop
} catch {
    Write-ErrorLog "File and Printer Sharing firewall rules failed: $($_.Exception.Message)"
}

# 6. Require a password on wakeup
Write-Host "[*] Enforcing Password Requirement on Wakeup..." -ForegroundColor Yellow
foreach ($pc in @(
        @("/SETACVALUEINDEX", "SCHEME_CURRENT", "SUB_NONE", "CONSOLELOCK", "1"),
        @("/SETDCVALUEINDEX", "SCHEME_CURRENT", "SUB_NONE", "CONSOLELOCK", "1"),
        @("/SETACTIVE",       "SCHEME_CURRENT"))) {
    $out = powercfg @pc 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-ErrorLog "powercfg $($pc -join ' ') failed (exit code $LASTEXITCODE): $($out -join ' ')"
    }
}
# Policy-level enforcement of the same setting
$PowerPolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Power\PowerSettings\0e796bdb-100d-47d6-a2d5-f7d2daa51f51"
Set-RegValue -Path $PowerPolicy -Name "ACSettingIndex" -Value 1 -Type DWord
Set-RegValue -Path $PowerPolicy -Name "DCSettingIndex" -Value 1 -Type DWord

# 7. Internet Options (Internet zone) & TLS protocol hardening
Write-Host "[*] Hardening Internet Options and SCHANNEL protocols..." -ForegroundColor Yellow
$InternetSettingsPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
Set-RegValue -Path $InternetSettingsPath -Name "AutoDetect" -Value 0 -Type DWord

# Internet zone (3): disable unsigned ActiveX download and unsafe ActiveX scripting, keep Protected Mode on
$InternetZone = "$InternetSettingsPath\Zones\3"
Set-RegValue -Path $InternetZone -Name "1004" -Value 3 -Type DWord   # Download unsigned ActiveX: Disable
Set-RegValue -Path $InternetZone -Name "1201" -Value 3 -Type DWord   # ActiveX not marked safe: Disable
Set-RegValue -Path $InternetZone -Name "2500" -Value 0 -Type DWord   # Protected Mode: Enabled

# Disable legacy protocols and enable TLS 1.2 (and 1.3 where the OS supports it), for both Client and Server.
# TLS 1.3 is supported on Windows 11 and Server 2022 only.
$Tls13Supported = ($WindowsVersion -match "Windows 11|Server 2022|Server 2025")

$SchProtocols = @(
    @{ Proto = "SSL 2.0"; Enabled = 0 },
    @{ Proto = "SSL 3.0"; Enabled = 0 },
    @{ Proto = "TLS 1.0"; Enabled = 0 },
    @{ Proto = "TLS 1.1"; Enabled = 0 },
    @{ Proto = "TLS 1.2"; Enabled = 1 }
)
if ($Tls13Supported) { $SchProtocols += @{ Proto = "TLS 1.3"; Enabled = 1 } }

$SchBase = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols"
foreach ($p in $SchProtocols) {
    foreach ($role in @("Client", "Server")) {
        $path = "$SchBase\$($p.Proto)\$role"
        Set-RegValue -Path $path -Name "Enabled"           -Value $p.Enabled                                  -Type DWord
        Set-RegValue -Path $path -Name "DisabledByDefault" -Value $(if ($p.Enabled -eq 1) { 0 } else { 1 })   -Type DWord
    }
}

if ($script:Failures -eq 0) {
    Write-Host "[+] Security hardening baseline applied successfully." -ForegroundColor Green
} else {
    Write-Host "[!] Baseline applied with $($script:Failures) error(s). See $ErrorLogPath" -ForegroundColor Yellow
}
Write-Host "[*] Restart is required for SCHANNEL changes; sign out/in for HKCU changes to fully apply." -ForegroundColor Cyan