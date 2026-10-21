[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$WindowsVersion = "Windows 11"
)

$ScriptName = Split-Path $PSCommandPath -Leaf
$ErrorLog   = Join-Path (Get-Location).Path "errors.log"
$script:Failures = 0

# Runs one step; any terminating error or non-zero native exit code is logged
# to errors.log as: timestamp | script file | command attempted | error.
function Invoke-Step {
    param([string]$Command, [scriptblock]$Action)
    try {
        $ErrorActionPreference = 'Stop'
        $global:LASTEXITCODE = 0
        & $Action | Out-Host
        if ($LASTEXITCODE -ne 0) { throw "Exit code $LASTEXITCODE" }
    } catch {
        $script:Failures++
        Add-Content -Path $ErrorLog -Value "[$(Get-Date -Format s)] $ScriptName | $Command | $($_.Exception.Message)"
        Write-Host "[-] Failed: $Command" -ForegroundColor Red
    }
}

# Sets a machine policy registry value (same keys the Group Policy editor writes).
function Set-Policy {
    param([string]$SubKey, [string]$Name, $Value, [string]$Kind = 'DWord')
    Invoke-Step "Set HKLM\$SubKey\$Name = $Value" {
        [Microsoft.Win32.Registry]::SetValue("HKEY_LOCAL_MACHINE\$SubKey", $Name, $Value, $Kind)
    }
}

Write-Host "[*] Applying security hardening for $WindowsVersion..." -ForegroundColor Cyan

# 1. PowerShell script block / module logging and transcription (GPO equivalents)
$psPolicy = 'SOFTWARE\Policies\Microsoft\Windows\PowerShell'
Set-Policy "$psPolicy\ScriptBlockLogging"           'EnableScriptBlockLogging' 1
Set-Policy "$psPolicy\ModuleLogging"                'EnableModuleLogging'      1
Set-Policy "$psPolicy\ModuleLogging\ModuleNames"    '*'                        '*' 'String'
Set-Policy "$psPolicy\Transcription"                'EnableTranscripting'      1

# 2. Verify PowerShell version
Invoke-Step '$PSVersionTable.PSVersion' { $PSVersionTable.PSVersion }

# 6. Execution policy
Invoke-Step 'Set-ExecutionPolicy RemoteSigned -Scope LocalMachine' {
    Set-ExecutionPolicy RemoteSigned -Scope LocalMachine -Force
}
Invoke-Step 'Get-ExecutionPolicy -List' { Get-ExecutionPolicy -List }

# 7. System file integrity repair (DISM first so SFC has a healthy component store)
Invoke-Step 'DISM /Online /Cleanup-Image /RestoreHealth' { DISM /Online /Cleanup-Image /RestoreHealth }
Invoke-Step 'sfc /scannow' { sfc /scannow }

# 8. DNS cache forensics, then flush
Invoke-Step 'Get-DnsClientCache | Out-File C:\dns_cache_audit.txt' {
    Get-DnsClientCache | Format-Table -AutoSize | Out-File -FilePath C:\dns_cache_audit.txt -Encoding utf8
}
Invoke-Step 'Clear-DnsClientCache' { Clear-DnsClientCache }

# 4. Scheduled tasks audit
Invoke-Step 'schtasks /query /fo LIST /v | Out-File C:\tasks_audit.txt' {
    schtasks /query /fo LIST /v | Out-File -FilePath C:\tasks_audit.txt -Encoding utf8
}

# 5/9. Listening ports mapped to owning process and path (covers netstat -ano | findstr LISTENING)
Invoke-Step 'Get-NetTCPConnection -State Listen' {
    Get-NetTCPConnection -State Listen |
        Select-Object LocalAddress, LocalPort, OwningProcess,
            @{Name = "ProcessName"; Expression = { (Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName }},
            @{Name = "Path";        Expression = { (Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).Path }} |
        Sort-Object LocalPort | Format-Table -AutoSize
}

# 10. SMB shares, sessions and open files
Invoke-Step 'Get-SmbShare'    { Get-SmbShare    | Format-Table -AutoSize }
Invoke-Step 'Get-SmbSession'  { Get-SmbSession  | Format-Table -AutoSize }
Invoke-Step 'Get-SmbOpenFile' { Get-SmbOpenFile | Format-Table -AutoSize }

# 3. Group Policy refresh (last, so it applies everything above)
Invoke-Step 'gpupdate /force' { gpupdate /force }

if ($script:Failures -eq 0) {
    Write-Host "[+] Hardening applied successfully." -ForegroundColor Green
} else {
    Write-Host "[!] Completed with $($script:Failures) error(s). See $ErrorLog" -ForegroundColor Yellow
}