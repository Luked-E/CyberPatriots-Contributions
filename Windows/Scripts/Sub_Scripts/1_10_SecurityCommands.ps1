[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$WindowsVersion = "Windows 11"
)

$ParentDir = [System.IO.Directory]::GetParent($PSScriptRoot).FullName
Import-Module -Name "$ParentDir\EngineUtils.psd1" -Force
Assert-AdminPrivileges

$ErrorActionPreference = 'Stop'

Write-Host "[*] Applying security hardening for $WindowsVersion..." -ForegroundColor Cyan

# 1. PowerShell script block / module logging and transcription (GPO equivalents)
$psPolicy = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell'
Set-RegValue "$psPolicy\ScriptBlockLogging"        'EnableScriptBlockLogging' 1
Set-RegValue "$psPolicy\ModuleLogging"             'EnableModuleLogging'      1
Set-RegValue "$psPolicy\ModuleLogging\ModuleNames" '*'                        '*' 'String'
Set-RegValue "$psPolicy\Transcription"             'EnableTranscripting'      1

# 2. Verify PowerShell version
Invoke-Step '$PSVersionTable.PSVersion' { $PSVersionTable.PSVersion | Out-Host }

# 6. Execution policy
Invoke-Step 'Set-ExecutionPolicy RemoteSigned -Scope LocalMachine' {
    Set-ExecutionPolicy RemoteSigned -Scope LocalMachine -Force
}
Invoke-Step 'Get-ExecutionPolicy -List' { Get-ExecutionPolicy -List | Out-Host }

# 7. DNS cache forensics, then flush
Invoke-Step 'Get-DnsClientCache | Out-File C:\dns_cache_audit.txt' {
    # Ensure Dnscache service is running before querying
    $dnsService = Get-Service -Name "Dnscache" -ErrorAction SilentlyContinue
    if ($dnsService -and $dnsService.Status -ne 'Running') {
        Start-Service -Name "Dnscache" -ErrorAction SilentlyContinue
    }
    Get-DnsClientCache | Format-Table -AutoSize | Out-File -FilePath C:\dns_cache_audit.txt -Encoding utf8
}

Invoke-Step 'Clear DNS Cache (ipconfig /flushdns)' {
    # ipconfig is robust and bypasses CIM provider errors
    cmd.exe /c "ipconfig /flushdns" | Out-Host
}

# 4. Scheduled tasks audit
Invoke-Step 'schtasks /query /fo LIST /v | Out-File C:\tasks_audit.txt' {
    schtasks /query /fo LIST /v | Out-File -FilePath C:\tasks_audit.txt -Encoding utf8
}

# 5/8. Listening ports mapped to owning process and path (covers netstat -ano | findstr LISTENING)
Invoke-Step 'Get-NetTCPConnection -State Listen' {
    Get-NetTCPConnection -State Listen |
        Select-Object LocalAddress, LocalPort, OwningProcess,
            @{Name = "ProcessName"; Expression = { (Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName }},
            @{Name = "Path";        Expression = { (Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).Path }} |
        Sort-Object LocalPort | Format-Table -AutoSize | Out-Host
}

# 9. SMB shares, sessions and open files
Invoke-Step 'Get-SmbShare'    { Get-SmbShare    | Format-Table -AutoSize | Out-Host }
Invoke-Step 'Get-SmbSession'  { Get-SmbSession  | Format-Table -AutoSize | Out-Host }
Invoke-Step 'Get-SmbOpenFile' { Get-SmbOpenFile | Format-Table -AutoSize | Out-Host }

# 3. Group Policy refresh (last, so it applies everything above)
Invoke-Step 'gpupdate /force' { gpupdate /force | Out-Host }

Write-Host "[+] Hardening complete. Any errors were written to the Logs directory." -ForegroundColor Green