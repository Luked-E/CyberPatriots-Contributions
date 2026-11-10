[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$WindowsVersion = "Windows 11",

    [Parameter(Mandatory = $false)]
    [ValidateSet("Disabled", "Enabled")]
    [string]$ApacheState = "Disabled"
)

$ParentDir = [System.IO.Directory]::GetParent($PSScriptRoot).FullName
Import-Module -Name "$ParentDir\EngineUtils.psd1" -Force
Assert-AdminPrivileges

Write-Host "[*] Applying Apache hardening for $WindowsVersion (Apache: $ApacheState)..." -ForegroundColor Cyan

$ErrorActionPreference = 'Stop'
$ApacheRoot = 'C:\Apache24'
$conf       = "$ApacheRoot\conf\httpd.conf"
$SystemSid  = '*S-1-5-18'
$AdminsSid  = '*S-1-5-32-544'
# Remove inherited ACEs; leave only SYSTEM and Administrators with Full Control
$LockDown   = @('/inheritance:r', '/grant:r', "${SystemSid}:(OI)(CI)F", "${AdminsSid}:(OI)(CI)F")

if ($ApacheState -eq 'Disabled') {
    foreach ($svc in Get-Service -Name 'Apache*' -ErrorAction SilentlyContinue) {
        Invoke-Step -Action { Stop-Service -Name $svc.Name -Force; Set-Service -Name $svc.Name -StartupType Disabled }
    }
}
elseif (Test-Path -LiteralPath $conf) {
    Invoke-Step -Action {
        $text = [IO.File]::ReadAllText($conf)

        $text = $text -replace '(?m)^([ \t]*)Options[ \t]+[^\r\n#]*\bIndexes\b[^\r\n]*', '$1Options -Indexes +FollowSymLinks'
        $text = $text -replace '(?m)^([ \t]*)AllowOverride[ \t]+(?!None\b)[^\r\n]+', '$1AllowOverride None'
        $text = $text -replace '(?m)^([ \t]*Include[ \t]+conf/extra/httpd-info\.conf)', '#$1'

        $directives = [ordered]@{ TraceEnable = 'Off'; ServerTokens = 'Prod'; ServerSignature = 'Off'; Timeout = '60'; KeepAliveTimeout = '5' }
        foreach ($d in $directives.GetEnumerator()) {
            $line = "$($d.Key) $($d.Value)"
            if ($text -match "(?m)^[ \t]*$($d.Key)[ \t]") {
                $text = $text -replace "(?m)^[ \t]*$($d.Key)[ \t][^\r\n]*", $line
            } else {
                $text += "`r`n$line"
            }
        }

        Copy-Item -LiteralPath $conf -Destination "$conf.bak" -Force
        [IO.File]::WriteAllText($conf, $text)
        & "$ApacheRoot\bin\httpd.exe" -t 2>$null
        if ($LASTEXITCODE -ne 0) {
            Copy-Item -LiteralPath "$conf.bak" -Destination $conf -Force
            throw "httpd.exe -t rejected the new configuration; httpd.conf restored from backup"
        }
    }

    Invoke-Step -Action { Get-ChildItem "$ApacheRoot\htdocs" -Recurse -Include 'test.php', 'info.php', 'phpinfo.php' | Remove-Item -Force }
    Invoke-Step -Action { icacls "$ApacheRoot\htdocs" @LockDown | Out-Null }
    Invoke-Step -Action { auditpol /set /subcategory:"{0CCE921D-69AE-11D9-BED3-505054503030}" /success:enable /failure:enable | Out-Null }
    Invoke-Step -Action {
        $acl = Get-Acl -Path "$ApacheRoot\htdocs" -Audit
        $acl.AddAuditRule([Security.AccessControl.FileSystemAuditRule]::new([Security.Principal.SecurityIdentifier]'S-1-1-0', 'Modify', 'ContainerInherit,ObjectInherit', 'None', 'Success,Failure'))
        Set-Acl -Path "$ApacheRoot\htdocs" -AclObject $acl
    }

    foreach ($svc in Get-Service -Name 'Apache*' -ErrorAction SilentlyContinue | Where-Object Status -eq 'Running') {
        Invoke-Step -Action { Restart-Service -Name $svc.Name -Force }
    }
}

Write-Host "[+] Apache hardening applied. Any failures are logged to the Logs folder." -ForegroundColor Green
