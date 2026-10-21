[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$WindowsVersion = "Windows 11"
)

# Any non-terminating error becomes terminating so Invoke-Step can log it.
$ErrorActionPreference = 'Stop'
$LogSizeKB  = 65536
$ScriptName = $MyInvocation.MyCommand.Name
$ErrorLog   = Join-Path (Get-Location).Path 'errors.log'
$script:ErrorCount = 0

# Runs one action; on any failure appends "time | script | command | message" to errors.log.
function Invoke-Step {
    param([string]$Command, [scriptblock]$Action)
    try {
        $global:LASTEXITCODE = 0
        & $Action | Out-Host
        if ($LASTEXITCODE -ne 0) { throw "Exit code $LASTEXITCODE" }
    } catch {
        $script:ErrorCount++
        Add-Content -Path $ErrorLog -Value ("[{0}] {1} | {2} | {3}" -f (Get-Date -Format s), $ScriptName, $Command, $_.Exception.Message)
        Write-Host "[-] Failed: $Command (logged to $ErrorLog)" -ForegroundColor Red
    }
}

Write-Host "[*] Applying Computer Management hardening for $WindowsVersion (Min log size: $LogSizeKB KB)..." -ForegroundColor Cyan

# 1. Disk Management & File System Integrity: convert FAT/FAT32 volumes to NTFS
Write-Host "[*] 1. Checking volume file systems..." -ForegroundColor Cyan
Invoke-Step "Get-Volume (FAT/FAT32 check)" {
    Get-Volume | Where-Object { $_.DriveLetter -and $_.FileSystem -in 'FAT', 'FAT32' } | ForEach-Object {
        $drive = "$($_.DriveLetter):"
        Invoke-Step "convert.exe $drive /fs:ntfs" { 'Y' | convert.exe $drive /fs:ntfs }
    }
}

# 2. Event Viewer Log Sizes & Settings
Write-Host "[*] 2. Configuring event log size and retention..." -ForegroundColor Cyan
foreach ($name in 'Security', 'System', 'Application') {
    Invoke-Step "Configure '$name' log (min $LogSizeKB KB, overwrite as needed)" {
        $log = Get-WinEvent -ListLog $name
        if ($log.MaximumSizeInBytes -lt ($LogSizeKB * 1KB)) { $log.MaximumSizeInBytes = $LogSizeKB * 1KB }
        $log.LogMode = 'Circular'
        $log.SaveChanges()
    }
}

# 3. Device Manager Hidden Device Audit: remove rogue virtual network adapters and their drivers
Write-Host "[*] 3. Removing rogue virtual network adapters..." -ForegroundColor Cyan
Invoke-Step "Get-PnpDevice -Class Net (rogue adapter check)" {
    $infs = foreach ($dev in Get-PnpDevice -Class Net | Where-Object FriendlyName -Match 'TAP-Windows|TeamViewer VPN|Hamachi|OpenVPN') {
        $id = $dev.InstanceId
        # Read the driver INF before the device is removed.
        (Get-PnpDeviceProperty -InstanceId $id -KeyName DEVPKEY_Device_DriverInfPath -ErrorAction SilentlyContinue).Data
        Invoke-Step "pnputil.exe /remove-device `"$id`" ($($dev.FriendlyName))" { pnputil.exe /remove-device $id }
    }
    # Drivers can be shared between adapters, so delete each unique INF once.
    $infs | Where-Object { $_ -like 'oem*.inf' } | Sort-Object -Unique | ForEach-Object {
        $inf = $_
        Invoke-Step "pnputil.exe /delete-driver $inf /uninstall /force" { pnputil.exe /delete-driver $inf /uninstall /force }
    }
}

# 4. Security Event Log Threat Hunting (report only)
Write-Host "[*] 4. Security event log threat hunting report..." -ForegroundColor Cyan
Invoke-Step "Get-WinEvent Security Ids 4624,4625,4720,4726,4728,4732,4697,1102" {
    $sec = Get-WinEvent -FilterHashtable @{ LogName = 'Security'; Id = 4624, 4625, 4720, 4726, 4728, 4732, 4697, 1102 } -MaxEvents 5000 -ErrorAction SilentlyContinue
    Write-Host "Event counts (newest 5000 matching events):"
    $sec | Group-Object Id | Sort-Object Name | Format-Table @{n = 'EventId'; e = { $_.Name } }, Count -AutoSize
    $remote = @($sec | Where-Object { $_.Id -eq 4624 -and $_.Properties[8].Value -in 3, 10 }).Count
    Write-Host "Successful network/RDP logons (4624, type 3 or 10): $remote"
    Write-Host "Account, group, service and log-clear events:"
    $sec | Where-Object { $_.Id -notin 4624, 4625 } |
        Format-Table TimeCreated, Id, @{n = 'Summary'; e = { ($_.Message -split "`r?`n")[0] } } -AutoSize -Wrap
}
Invoke-Step "Get-WinEvent System Id 7045" {
    Write-Host "New services installed (7045):"
    Get-WinEvent -FilterHashtable @{ LogName = 'System'; Id = 7045 } -MaxEvents 20 -ErrorAction SilentlyContinue |
        Format-Table TimeCreated, @{n = 'ServiceName'; e = { $_.Properties[0].Value } }, @{n = 'ImagePath'; e = { $_.Properties[1].Value } } -AutoSize -Wrap
}

# 5. Shared Folders: stop non-default shares, close sessions, list open files
Write-Host "[*] 5. Cleaning up shares and sessions..." -ForegroundColor Cyan
Invoke-Step "Get-SmbShare (non-default shares)" {
    Get-SmbShare | Where-Object { -not $_.Special -and $_.Name -ne 'print$' } | ForEach-Object {
        $share = $_.Name
        Invoke-Step "Remove-SmbShare -Name '$share' -Force" { Remove-SmbShare -Name $share -Force }
    }
}
Invoke-Step "Get-SmbSession | Close-SmbSession -Force" { Get-SmbSession | Close-SmbSession -Force }
Invoke-Step "Get-SmbOpenFile" {
    Write-Host "Files open over the network:"
    Get-SmbOpenFile | Format-Table ClientComputerName, ClientUserName, Path -AutoSize
}

if ($script:ErrorCount -gt 0) {
    Write-Host "[!] Completed with $script:ErrorCount error(s). See $ErrorLog" -ForegroundColor Yellow
} else {
    Write-Host "[+] Hardening applied successfully." -ForegroundColor Green
}