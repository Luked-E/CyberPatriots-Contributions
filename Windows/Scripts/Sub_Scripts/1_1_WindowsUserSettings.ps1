[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$WindowsVersion = "Windows 11",

    [Parameter(Mandatory = $false)]
    [ValidateSet("Disabled", "LocalNetwork")]
    [string]$DeliveryOptimizationMode = "Disabled"
)

Write-Host "[*] Applying Windows Settings hardening (AutoPlay, Privacy, Delivery Optimization, Developer Mode, Lock Screen Notifications, Clipboard) for $WindowsVersion..." -ForegroundColor Cyan

# 1. AutoPlay Configuration
Write-Host "[*] Disabling AutoPlay for all media and devices..." -ForegroundColor Yellow
$AutoPlayPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"
if (!(Test-Path $AutoPlayPath)) {
    New-Item -Path $AutoPlayPath -Force | Out-Null
}
Set-ItemProperty -Path $AutoPlayPath -Name "NoDriveTypeAutoRun" -Value 255 -Type DWord
Set-ItemProperty -Path $AutoPlayPath -Name "NoAutorun" -Value 1 -Type DWord

$UserAutoPlayPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers"
if (!(Test-Path $UserAutoPlayPath)) {
    New-Item -Path $UserAutoPlayPath -Force | Out-Null
}
Set-ItemProperty -Path $UserAutoPlayPath -Name "DisableAutoplay" -Value 1 -Type DWord

# 2. Privacy & Diagnostic Telemetry
Write-Host "[*] Configuring telemetry and privacy settings..." -ForegroundColor Yellow
$TelemetryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
if (!(Test-Path $TelemetryPath)) {
    New-Item -Path $TelemetryPath -Force | Out-Null
}
Set-ItemProperty -Path $TelemetryPath -Name "AllowTelemetry" -Value 0 -Type DWord

# 3. Delivery Optimization Peer-to-Peer Update Sharing
Write-Host "[*] Configuring Delivery Optimization mode: $DeliveryOptimizationMode..." -ForegroundColor Yellow
$DOPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization"
if (!(Test-Path $DOPath)) {
    New-Item -Path $DOPath -Force | Out-Null
}
$DoValue = switch ($DeliveryOptimizationMode) {
    "Disabled"     { 0 }
    "LocalNetwork" { 1 }
    default        { 0 }
}
Set-ItemProperty -Path $DOPath -Name "DODownloadMode" -Value $DoValue -Type DWord

# 4. Turn Off Developer Mode
Write-Host "[*] Disabling Developer Mode and app sideloading..." -ForegroundColor Yellow
$DevModePath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
if (!(Test-Path $DevModePath)) {
    New-Item -Path $DevModePath -Force | Out-Null
}
Set-ItemProperty -Path $DevModePath -Name "AllowDevelopmentWithoutDevLicense" -Value 0 -Type DWord
Set-ItemProperty -Path $DevModePath -Name "AllowAllTrustedApps" -Value 0 -Type DWord

$AppDeploymentPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Appx"
if (!(Test-Path $AppDeploymentPath)) {
    New-Item -Path $AppDeploymentPath -Force | Out-Null
}
Set-ItemProperty -Path $AppDeploymentPath -Name "AllowDevelopmentWithoutDevLicense" -Value 0 -Type DWord
Set-ItemProperty -Path $AppDeploymentPath -Name "AllowAllTrustedApps" -Value 0 -Type DWord

# 5. Disable Lock Screen Notification Previews
Write-Host "[*] Disabling lock screen notification previews..." -ForegroundColor Yellow
$LockScreenPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
if (!(Test-Path $LockScreenPath)) {
    New-Item -Path $LockScreenPath -Force | Out-Null
}
Set-ItemProperty -Path $LockScreenPath -Name "DisableLockScreenAppNotifications" -Value 1 -Type DWord

# 6. Disable Clipboard History & Cross-Device Cloud Sync
Write-Host "[*] Disabling Clipboard history and cross-device sync..." -ForegroundColor Yellow
$ClipPolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
if (!(Test-Path $ClipPolicyPath)) {
    New-Item -Path $ClipPolicyPath -Force | Out-Null
}
Set-ItemProperty -Path $ClipPolicyPath -Name "AllowClipboardHistory" -Value 0 -Type DWord
Set-ItemProperty -Path $ClipPolicyPath -Name "AllowCrossDeviceClipboard" -Value 0 -Type DWord

$UserClipPath = "HKCU:\Software\Microsoft\Clipboard"
if (!(Test-Path $UserClipPath)) {
    New-Item -Path $UserClipPath -Force | Out-Null
}
Set-ItemProperty -Path $UserClipPath -Name "EnableClipboardHistory" -Value 0 -Type DWord

Write-Host "[+] All Windows Settings security configurations applied successfully." -ForegroundColor Green