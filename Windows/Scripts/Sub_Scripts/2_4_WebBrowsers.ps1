[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$WindowsVersion = "Windows 11",

    [Parameter(Mandatory = $false)]
    [ValidateSet("None", "Edge", "Chrome", "Firefox")]
    [string]$Browser = "Edge",

    [Parameter(Mandatory = $false)]
    [ValidateSet("Disabled", "Enabled")]
    [string]$InternetExplorerState = "Disabled"
)

$ParentDir = [System.IO.Directory]::GetParent($PSScriptRoot).FullName
Import-Module -Name "$ParentDir\EngineUtils.psd1" -Force
Assert-AdminPrivileges

$ErrorActionPreference = 'Stop'

Write-Host "[*] Applying browser hardening for $WindowsVersion (Browser: $Browser, IE State: $InternetExplorerState)..." -ForegroundColor Cyan

# Browser catalog: winget ID (null = not removable) and Programs and Features display name.
$browserCatalog = @{
    Edge    = @{ Id = 'Microsoft.Edge';  Name = $null }            # System component on Windows 11; never uninstalled
    Chrome  = @{ Id = 'Google.Chrome';   Name = 'Google Chrome' }
    Firefox = @{ Id = 'Mozilla.Firefox'; Name = 'Mozilla Firefox' }
}

# --- 1. Update the selected browser (winget ships with Windows 11) ---
if ($Browser -ne "None") {
    $id = $browserCatalog[$Browser].Id
    Invoke-Step "winget upgrade --id $id" {
        if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { throw "winget not found" }
        try {
            winget upgrade --id $id --exact --source winget --silent --accept-source-agreements --accept-package-agreements | Out-Null
        } catch {
            Write-Host "[!] Winget online source query failed or blocked. Skipping application update." -ForegroundColor Yellow
        }
    }
}

# --- 2. Browser policies (HKLM policy keys are what the browsers read on Windows 11) ---
$chrome  = 'HKLM:\SOFTWARE\Policies\Google\Chrome'
$edge    = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
$firefox = 'HKLM:\SOFTWARE\Policies\Mozilla\Firefox'
$ffPrefs = "$firefox\Preferences"

# Chrome
Set-RegValue $chrome 'AdsSettingForIntrusiveAdsSites' 2   # Block intrusive ads
Set-RegValue $chrome 'DefaultPopupsSetting'           2   # Block pop-ups/redirects
Set-RegValue $chrome 'SafeBrowsingProtectionLevel'    2   # Enhanced protection
Set-RegValue $chrome 'BlockThirdPartyCookies'         1
Set-RegValue $chrome 'PasswordManagerEnabled'         0

# Edge
Set-RegValue $edge 'SmartScreenEnabled'     1
Set-RegValue $edge 'SmartScreenPuaEnabled'  1             # Block potentially unwanted apps
Set-RegValue $edge 'PasswordManagerEnabled' 0

# Firefox
Set-RegValue $firefox 'AppAutoUpdate' 1
Set-RegValue "$firefox\PopupBlocking" 'Default' 1
Set-RegValue "$firefox\Permissions\Autoplay" 'Default' 'block-audio-video' 'String'
Set-RegValue $ffPrefs 'browser.safebrowsing.malware.enabled'                                  1
Set-RegValue $ffPrefs 'browser.safebrowsing.phishing.enabled'                                 1
Set-RegValue $ffPrefs 'browser.safebrowsing.downloads.enabled'                                1
Set-RegValue $ffPrefs 'browser.safebrowsing.downloads.remote.block_potentially_unwanted'      1
Set-RegValue $ffPrefs 'browser.safebrowsing.downloads.remote.block_uncommon'                  1
Set-RegValue $ffPrefs 'xpinstall.whitelist.required'                                          1   # Warn on add-on installs

# --- 3. Internet Explorer (not present on Windows 11) ---
if ($WindowsVersion -like "*Windows 11*") {
    Write-Host "[*] Internet Explorer is removed from Windows 11; skipping IE settings." -ForegroundColor Yellow
}
else {
    if ($WindowsVersion -notlike "*Server*") {
        $feature = 'Internet-Explorer-Optional-amd64'
        if ($InternetExplorerState -eq "Enabled") {
            Invoke-Step "Enable-WindowsOptionalFeature $feature" { Enable-WindowsOptionalFeature -Online -FeatureName $feature -NoRestart | Out-Null }
        }
        else {
            Invoke-Step "Disable-WindowsOptionalFeature $feature" { Disable-WindowsOptionalFeature -Online -FeatureName $feature -NoRestart | Out-Null }
        }
    }

    if ($InternetExplorerState -eq "Enabled") {
        $flash = '{D27CDB6E-AE6D-11cf-96B8-444553540000}'
        Set-RegValue 'HKCU:\SOFTWARE\Microsoft\Internet Explorer\New Windows'                 'PopupMgr'          1
        Set-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Internet Explorer\Restrictions'       'NoPopupManagement' 0
        # Flash kill bit (64-bit and 32-bit views)
        Set-RegValue "HKLM:\SOFTWARE\Microsoft\Internet Explorer\ActiveX Compatibility\$flash"             'Compatibility Flags' 0x400
        Set-RegValue "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Internet Explorer\ActiveX Compatibility\$flash" 'Compatibility Flags' 0x400
    }
}

# --- 4. Remove every browser that was not selected ---
$unapproved = @('Tor Browser', 'Brave', 'Opera', 'Vivaldi', 'UC Browser') +
    @($browserCatalog.Keys | Where-Object { $_ -ne $Browser -and $browserCatalog[$_].Name } | ForEach-Object { $browserCatalog[$_].Name })
$uninstallKeys = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
                 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
                 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'

$apps = Get-ItemProperty -Path $uninstallKeys -ErrorAction SilentlyContinue |
    Where-Object { $n = $_.DisplayName; $n -and ($unapproved | Where-Object { $n -like "$_*" }) }

foreach ($app in $apps) {
    Invoke-Step "Uninstall $($app.DisplayName)" {
        $cmd = if ($app.QuietUninstallString)               { $app.QuietUninstallString }
               elseif ($app.UninstallString -match 'msiexec') { ($app.UninstallString -replace '/I', '/X') + ' /qn /norestart' }
               else                                          { $app.UninstallString }
        if (-not $cmd) { throw "No uninstall string found" }
        $proc = Start-Process -FilePath cmd.exe -ArgumentList "/c $cmd" -Wait -PassThru -WindowStyle Hidden
        if ($proc.ExitCode -ne 0) { throw "Uninstaller exit code $($proc.ExitCode)" }
    }
}

Write-Host "[+] Browser hardening applied successfully." -ForegroundColor Green