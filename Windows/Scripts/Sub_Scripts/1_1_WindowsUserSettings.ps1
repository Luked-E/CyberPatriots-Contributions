[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$WindowsVersion = "Windows 11",

    [Parameter(Mandatory = $false)]
    [ValidateSet("Disabled", "LocalNetwork")]
    [string]$DeliveryOptimizationMode = "Disabled"
)

# Import EngineUtils and verify administrator privileges[cite: 3]
$ParentDir = [System.IO.Directory]::GetParent($PSScriptRoot).FullName
Import-Module -Name "$ParentDir\EngineUtils.psd1" -Force
Assert-AdminPrivileges

$ErrorActionPreference = 'Stop'
$ErrorLog   = Join-Path (Get-Location).Path "errors.log"
$script:Failures = 0

Write-Host "[*] Applying Windows Settings hardening (AutoPlay, Privacy, Delivery Optimization, Developer Mode, Lock Screen Notifications, Clipboard) for $WindowsVersion..." -ForegroundColor Cyan

# 1. AutoPlay Configuration
Write-Host "[*] Disabling AutoPlay for all media and devices..." -ForegroundColor Yellow
$AutoPlayPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"
Set-RegValue -Path $AutoPlayPath -Name "NoDriveTypeAutoRun" -Value 255 -Type "DWord"
Set-RegValue -Path $AutoPlayPath -Name "NoAutorun" -Value 1 -Type "DWord"

$UserAutoPlayPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers"
Set-RegValue -Path $UserAutoPlayPath -Name "DisableAutoplay" -Value 1 -Type "DWord"

# 2. Privacy & Diagnostic Telemetry
Write-Host "[*] Configuring telemetry and privacy settings..." -ForegroundColor Yellow
$TelemetryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
Set-RegValue -Path $TelemetryPath -Name "AllowTelemetry" -Value 0 -Type "DWord"

# 3. Delivery Optimization Peer-to-Peer Update Sharing
Write-Host "[*] Configuring Delivery Optimization mode: $DeliveryOptimizationMode..." -ForegroundColor Yellow
$DOPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization"
$DoValue = switch ($DeliveryOptimizationMode) {
    "Disabled"     { 0 }
    "LocalNetwork" { 1 }
    default        { 0 }
}
Set-RegValue -Path $DOPath -Name "DODownloadMode" -Value $DoValue -Type "DWord"

# 4. Turn Off Developer Mode
Write-Host "[*] Disabling Developer Mode and app sideloading..." -ForegroundColor Yellow
$DevModePath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
Set-RegValue -Path $DevModePath -Name "AllowDevelopmentWithoutDevLicense" -Value 0 -Type "DWord"
Set-RegValue -Path $DevModePath -Name "AllowAllTrustedApps" -Value 0 -Type "DWord"

$AppDeploymentPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Appx"
Set-RegValue -Path $AppDeploymentPath -Name "AllowDevelopmentWithoutDevLicense" -Value 0 -Type "DWord"
Set-RegValue -Path $AppDeploymentPath -Name "AllowAllTrustedApps" -Value 0 -Type "DWord"

# 5. Disable Lock Screen Notification Previews
Write-Host "[*] Disabling lock screen notification previews..." -ForegroundColor Yellow
$LockScreenPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
Set-RegValue -Path $LockScreenPath -Name "DisableLockScreenAppNotifications" -Value 1 -Type "DWord"

# 6. Disable Clipboard History & Cross-Device Cloud Sync
Write-Host "[*] Disabling Clipboard history and cross-device sync..." -ForegroundColor Yellow
$ClipPolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
Set-RegValue -Path $ClipPolicyPath -Name "AllowClipboardHistory" -Value 0 -Type "DWord"
Set-RegValue -Path $ClipPolicyPath -Name "AllowCrossDeviceClipboard" -Value 0 -Type "DWord"

$UserClipPath = "HKCU:\Software\Microsoft\Clipboard"
Set-RegValue -Path $UserClipPath -Name "EnableClipboardHistory" -Value 0 -Type "DWord"

if ($script:Failures -gt 0) {
    Write-Host "[!] Completed with $script:Failures failure(s). Check $ErrorLog for details." -ForegroundColor Yellow
} else {
    Write-Host "[+] All Windows Settings security configurations applied successfully." -ForegroundColor Green
}