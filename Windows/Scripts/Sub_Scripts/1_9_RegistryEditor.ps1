[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$WindowsVersion = "Windows 11"
)

$ParentDir = [System.IO.Directory]::GetParent($PSScriptRoot).FullName
$ModulePath = "$ParentDir\EngineUtils.psd1"

if (Test-Path $ModulePath) {
    Import-Module -Name $ModulePath -Force
    Assert-AdminPrivileges
} else {
    Write-Host "    [!] Required module not found at $ModulePath" -ForegroundColor Red
    throw "Module dependency missing: EngineUtils.psd1"
}

$ErrorActionPreference = 'Stop'

Write-Host "[*] Applying complete Section 1.9 registry hardening for $WindowsVersion..." -ForegroundColor Cyan

$Lsa      = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
$Session  = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager"
$Winlogon = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
$WinKey   = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows"

# 1. Static Registry Settings (Section 1.9 Items 1-5 & 7)
# Note: Set-RegValue internally handles error logging and Invoke-Step wrapping.
$settings = @(
    # 1. Disable CD/Media AutoRun
    @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer", "NoDriveTypeAutoRun", 255, "DWord"),

    # 2. Restrict anonymous SAM enumeration
    @($Lsa, "RestrictAnonymous",     1, "DWord"),
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
    @($WinKey, "AppInit_DLLs",    "", "String"),
    @($WinKey, "LoadAppInit_DLLs", 0,  "DWord")
)

# ===========================================================================
# VERSION-SPECIFIC LOGIC BRANCHING
# ===========================================================================
if ($WindowsVersion -like "*Windows 11*") {
    Write-Host "[*] Branching logic: Configuring Windows 11 specific baseline controls..." -ForegroundColor DarkCyan
    
    # Windows 11 supports enhanced virtualization-based security & LSA protection policies
    $settings += @(
        @($Lsa, "RunAsPPL", 1, "DWord"),
        @("HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent", "DisableWindowsConsumerFeatures", 1, "DWord")
    )
} 
else {
    Write-Host "[*] Branching logic: Configuring Windows 10 legacy baseline compatibility..." -ForegroundColor DarkCyan
    
    # Windows 10 specific telemetry/commercial adjustments
    $settings += @(
        @("HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection", "AllowTelemetry", 0, "DWord")
    )
}

foreach ($s in $settings) {
    Set-RegValue -Path $s[0] -Name $s[1] -Value $s[2] -Type $s[3]
}

Write-Host "[+] Static registry configurations applied successfully." -ForegroundColor Green

# 2. Dynamic Inspection & Cleanup for Run/RunOnce Hives (Section 1.9 Item 6)
Write-Host "[*] Scanning Run and RunOnce startup registry hives for persistence entries..." -ForegroundColor Cyan

$runPaths = @(
    "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
    "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce",
    "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run",
    "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\RunOnce",
    "Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run",
    "Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\RunOnce"
)

$foundEntries = $false

foreach ($path in $runPaths) {
    if (Test-Path $path) {
        $properties = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue
        # Filter out standard PSDrive properties
        $values = $properties.psobject.properties | Where-Object { 
            $_.Name -notmatch "^PS" 
        }

        if ($values) {
            $foundEntries = $true
            Write-Host "`n[!] Entries found in path: $path" -ForegroundColor Yellow
            foreach ($val in $values) {
                Write-Host "    -> Name: $($val.Name) | Data: $($val.Value)" -ForegroundColor DarkYellow
            }

            $choice = Read-Host "Would you like to (D)elete these entries, open `(R)egedit` to this location, or (S)kip?"
            
            if ($choice -eq 'D' -or $choice -eq 'd') {
                foreach ($val in $values) {
                    Invoke-Step -Command "Remove-ItemProperty -Path '$path' -Name '$($val.Name)'" -Action {
                        Remove-ItemProperty -Path $path -Name $val.Name -ErrorAction Stop
                    }
                    Write-Host "    [+] Deleted entry: $($val.Name)" -ForegroundColor Green
                }
            }
            elseif ($choice -eq 'R' -or $choice -eq 'r') {
                # Strip the PSDrive provider prefix and prepend 'Computer\' for registry jump compatibility
                $rawPath     = $path -replace "Registry::", ""
                $regeditPath = "Computer\$rawPath"
                $regKeyPath  = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Applets\Regedit"

                Invoke-Step -Command "Configure Regedit LastKey and launch Editor" -Action {
                    if (-not (Test-Path $regKeyPath)) {
                        New-Item -Path $regKeyPath -Force | Out-Null
                    }
                    Set-ItemProperty -Path $regKeyPath -Name "LastKey" -Value $regeditPath -ErrorAction Stop
                    Start-Process "regedit.exe"
                }
            }
        }
    }
}

if (-not $foundEntries) {
    Write-Host "[+] No persistence entries found in standard Run/RunOnce hives." -ForegroundColor Green
}

Write-Host "[+] Registry hardening and persistence audit complete." -ForegroundColor Green