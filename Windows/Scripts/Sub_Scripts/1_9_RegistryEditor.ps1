[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$WindowsVersion = "Windows 11"
)

$ScriptName = $MyInvocation.MyCommand.Name
$ErrorLog   = Join-Path (Get-Location).Path "errors.log"
$ErrorActionPreference = 'Stop'

Write-Host "[*] Applying registry hardening for $WindowsVersion..." -ForegroundColor Cyan

function Set-RegValue {
    param(
        [string]$Path,
        [string]$Name,
        $Value,
        [string]$Type
    )

    $command = "Set-ItemProperty -Path '$Path' -Name '$Name' -Value '$Value' -Type $Type"
    try {
        if (-not (Test-Path -LiteralPath $Path)) {
            New-Item -Path $Path -Force -ErrorAction Stop | Out-Null
        }
        Set-ItemProperty -LiteralPath $Path -Name $Name -Value $Value -Type $Type -Force -ErrorAction Stop
        Write-Host "[+] $Name = '$Value'" -ForegroundColor Green
    }
    catch {
        Write-Host "[-] Failed: $Name ($($_.Exception.Message))" -ForegroundColor Red
        Add-Content -Path $ErrorLog -Value "$(Get-Date -Format s) | $ScriptName | $command | $($_.Exception.Message)"
    }
}

$Lsa      = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
$Session  = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager"
$Winlogon = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
$WinKey   = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows"

# Path, Name, Value, Type
$settings = @(
    # 1. Disable CD/Media AutoRun
    @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer", "NoDriveTypeAutoRun", 255, "DWord"),

    # 2. Restrict anonymous SAM enumeration
    @($Lsa, "RestrictAnonymous",       1, "DWord"),
    @($Lsa, "RestrictAnonymousSAM",    1, "DWord"),
    @($Lsa, "LimitBlankPasswordUse",   1, "DWord"),

    # 3. Clear pagefile at shutdown
    @("$Session\Memory Management", "ClearPageFileAtShutdown", 1, "DWord"),

    # 4. Enforce safe DLL search mode
    @($Session, "SafeDllSearchMode", 1, "DWord"),

    # 5. Validate Winlogon Shell & Userinit integrity
    @($Winlogon, "Shell",    "explorer.exe", "String"),
    @($Winlogon, "Userinit", "C:\Windows\system32\userinit.exe,", "String"),

    # 7. Clean AppInit_DLLs injection keys
    @($WinKey, "AppInit_DLLs",     "", "String"),
    @($WinKey, "LoadAppInit_DLLs", 0,  "DWord")
)

foreach ($s in $settings) {
    Set-RegValue -Path $s[0] -Name $s[1] -Value $s[2] -Type $s[3]
}

Write-Host "[+] Registry hardening complete. Any errors were logged to $ErrorLog" -ForegroundColor Green