[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$WindowsVersion = "Windows 11",

    [Parameter(Mandatory = $false)]
    [ValidateSet("Disabled", "Enabled")]
    [string]$AbyssState = "Disabled"
)

$ParentDir = [System.IO.Directory]::GetParent($PSScriptRoot).FullName
Import-Module -Name "$ParentDir\EngineUtils.psd1" -Force
Assert-AdminPrivileges

Write-Host "[*] Configuring Abyss Web Server for $WindowsVersion (Abyss: $AbyssState)..." -ForegroundColor Cyan

$ErrorActionPreference = 'Stop'

if ($AbyssState -eq 'Disabled') {
    foreach ($svc in Get-Service | Where-Object { $_.Name -like '*Abyss*' -or $_.DisplayName -like '*Abyss*' }) {
        Invoke-Step -Action { Stop-Service -Name $svc.Name -Force; Set-Service -Name $svc.Name -StartupType Disabled }
    }
    # Abyss can also run outside the service (tray mode)
    if (Get-Process -Name 'abyssws' -ErrorAction SilentlyContinue) {
        Invoke-Step -Action { Stop-Process -Name 'abyssws' -Force }
    }

    # Uninstall is left to the user (Programs and Features) so a required server is never removed silently
    $uninstallKeys = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
                     'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    foreach ($app in Get-ItemProperty -Path $uninstallKeys -ErrorAction SilentlyContinue | Where-Object DisplayName -like 'Abyss Web Server*') {
        Write-WarningLog "$($app.DisplayName) is installed; uninstall it via Programs and Features (appwiz.cpl) unless the README authorizes it."
    }
}

Write-Host "[+] Abyss Web Server configuration applied. Any failures are logged to the Logs folder." -ForegroundColor Green
