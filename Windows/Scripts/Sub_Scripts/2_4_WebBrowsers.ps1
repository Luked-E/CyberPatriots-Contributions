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

$ScriptName = Split-Path -Leaf $PSCommandPath
$ErrorLog   = Join-Path (Get-Location).Path "errors.log"
$ErrorActionPreference = 'Stop'

Write-Host "[*] Applying browser hardening for $WindowsVersion (Browser: $Browser, IE State: $InternetExplorerState)..." -ForegroundColor Cyan

# Runs an action; on failure appends "file | command | error" to errors.log and continues.
function Invoke-Step {
    param([string]$Command, [scriptblock]$Action)
    try {
        & $Action
    }
    catch {
        Add-Content -Path $ErrorLog -Value "[$(Get-Date -Format s)] $ScriptName | $Command | $($_.Exception.Message)"
        Write-Host "[!] Failed: $Command (see errors.log)" -ForegroundColor Red
    }
}

# Writes registry values from a table of @{ Path; Name; Value }. Strings -> REG_SZ, numbers -> REG_DWORD.
function Set-RegistryValues {
    param([hashtable[]]$Entries)
    foreach ($e in $Entries) {
        $type = if ($e.Value -is [string]) { 'String' } else { 'DWord' }
        Invoke-Step "Set $($e.Path)\$($e.Name) = $($e.Value)" {
            if (-not (Test-Path $e.Path)) { New-Item -Path $e.Path -Force | Out-Null }
            New-ItemProperty -Path $e.Path -Name $e.Name -Value $e.Value -PropertyType $type -Force | Out-Null
        }
    }
}

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

Set-RegistryValues @(
    # Chrome
    @{ Path = $chrome; Name = 'AdsSettingForIntrusiveAdsSites'; Value = 2 }   # Block intrusive ads
    @{ Path = $chrome; Name = 'DefaultPopupsSetting';           Value = 2 }   # Block pop-ups/redirects
    @{ Path = $chrome; Name = 'SafeBrowsingProtectionLevel';    Value = 2 }   # Enhanced protection
    @{ Path = $chrome; Name = 'BlockThirdPartyCookies';         Value = 1 }
    @{ Path = $chrome; Name = 'PasswordManagerEnabled';         Value = 0 }

    # Edge
    @{ Path = $edge; Name = 'SmartScreenEnabled';    Value = 1 }
    @{ Path = $edge; Name = 'SmartScreenPuaEnabled'; Value = 1 }              # Block potentially unwanted apps
    @{ Path = $edge; Name = 'PasswordManagerEnabled'; Value = 0 }

    # Firefox
    @{ Path = $firefox;                    Name = 'AppAutoUpdate'; Value = 1 }
    @{ Path = "$firefox\PopupBlocking";    Name = 'Default';       Value = 1 }
    @{ Path = "$firefox\Permissions\Autoplay"; Name = 'Default';   Value = 'block-audio-video' }
    @{ Path = $ffPrefs; Name = 'browser.safebrowsing.malware.enabled';                       Value = 1 }
    @{ Path = $ffPrefs; Name = 'browser.safebrowsing.phishing.enabled';                      Value = 1 }
    @{ Path = $ffPrefs; Name = 'browser.safebrowsing.downloads.enabled';                     Value = 1 }
    @{ Path = $ffPrefs; Name = 'browser.safebrowsing.downloads.remote.block_potentially_unwanted'; Value = 1 }
    @{ Path = $ffPrefs; Name = 'browser.safebrowsing.downloads.remote.block_uncommon';       Value = 1 }
    @{ Path = $ffPrefs; Name = 'xpinstall.whitelist.required';                               Value = 1 }  # Warn on add-on installs
)

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
        Set-RegistryValues @(
            @{ Path = 'HKCU:\SOFTWARE\Microsoft\Internet Explorer\New Windows';                  Name = 'PopupMgr'; Value = 1 }
            @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Internet Explorer\Restrictions';        Name = 'NoPopupManagement'; Value = 0 }
            # Flash kill bit (64-bit and 32-bit views)
            @{ Path = "HKLM:\SOFTWARE\Microsoft\Internet Explorer\ActiveX Compatibility\$flash"; Name = 'Compatibility Flags'; Value = 0x400 }
            @{ Path = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Internet Explorer\ActiveX Compatibility\$flash"; Name = 'Compatibility Flags'; Value = 0x400 }
        )
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