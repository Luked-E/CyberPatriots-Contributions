[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$WindowsVersion = "Windows 11",

    [Parameter(Mandatory = $false)]
    [ValidateSet("Disabled", "Enabled")]
    [string]$SMB1State = "Disabled",

    [Parameter(Mandatory = $false)]
    [ValidateSet("Disabled", "Enabled")]
    [string]$SMBCompression = "Disabled"
)

$ErrorActionPreference = 'Stop'   # make every cmdlet failure catchable by Invoke-Step
$ScriptName = Split-Path -Leaf $PSCommandPath
$ErrorLog   = Join-Path (Get-Location).Path 'errors.log'

# Runs one action; on failure logs "time | script | command | error" to errors.log and continues.
function Invoke-Step {
    param([scriptblock]$Action, [string]$Command = $Action.ToString().Trim())
    try { & $Action }
    catch {
        Write-Host "[-] Failed: $Command" -ForegroundColor Red
        Add-Content -Path $ErrorLog -Value "$(Get-Date -Format s) | $ScriptName | $Command | $($_.Exception.Message)"
    }
}

Write-Host "[*] Applying SMB & file sharing hardening for $WindowsVersion (SMB1: $SMB1State, SMB Compression: $SMBCompression)..." -ForegroundColor Cyan

# --- 1. SMBv1 (optional feature + server config) ---
$smb1On = $SMB1State -eq 'Enabled'
$verb   = if ($smb1On) { 'Enable' } else { 'Disable' }
Invoke-Step { & "$verb-WindowsOptionalFeature" -Online -FeatureName SMB1Protocol -NoRestart | Out-Null }
Invoke-Step { Set-SmbServerConfiguration -EnableSMB1Protocol $smb1On -Force }
if ($smb1On) { Write-Host "[!] SMBv1 left enabled by request (insecure)." -ForegroundColor Yellow }

# --- 2. File shares: close open sessions, report (never delete) non-default shares ---
# Which custom shares are authorized depends on the README, so they are only listed.
Invoke-Step { Get-SmbSession | Close-SmbSession -Force }
Invoke-Step {
    Get-SmbShare -Special $false | ForEach-Object {
        Write-Host "[!] Non-default share '$($_.Name)' -> $($_.Path). Remove it only if the README doesn't require it." -ForegroundColor Yellow
    }
}

# --- 4. SMBv3 encryption ---
Invoke-Step { Set-SmbServerConfiguration -EncryptData $true -RejectUnencryptedAccess $true -Force }

# --- 6. SMB-In firewall rule: Domain/Private only (rule name is locale-independent) ---
Invoke-Step { Set-NetFirewallRule -Name 'FPS-SMB-In-TCP' -Profile Domain, Private }

# --- 3 & 5. Security options + SMBGhost, all registry-backed ---
$srv  = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters'
$wks  = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters'
$lsa  = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa'
$pipe = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurePipeServers\Winreg'
$none = [string[]]@()             # empty REG_MULTI_SZ ("enabled, string box blank")
$ntlmSec = 0x20080030             # NTLMv2 + 128-bit + message integrity + confidentiality

$settings = @(
    @($srv,  'RequireSecuritySignature', 1),          # server signing (always)
    @($srv,  'EnableSecuritySignature',  1),          # server signing (if client agrees)
    @($wks,  'RequireSecuritySignature', 1),          # client signing (always)
    @($wks,  'EnableSecuritySignature',  1),          # client signing (if server agrees)
    @($wks,  'EnablePlainTextPassword',  0),          # no unencrypted password to 3rd-party SMB
    @($srv,  'enableforcedlogoff',       1),          # disconnect when logon hours expire
    @($srv,  'RestrictNullSessAccess',   1),          # restrict anonymous pipes/shares
    @($srv,  'NullSessionPipes',         $none),      # anonymous named pipes: none
    @($srv,  'NullSessionShares',        $none),      # anonymous shares: none
    @($lsa,  'RestrictAnonymousSAM',     1),          # no anonymous SAM enumeration
    @($lsa,  'RestrictAnonymous',        1),          # no anonymous SAM + share enumeration
    @($lsa,  'DisableDomainCreds',       1),          # don't store network credentials
    @($lsa,  'EveryoneIncludesAnonymous', 0),         # Everyone excludes anonymous
    @($lsa,  'ForceGuest',               0),          # Classic local-account sharing model
    @($lsa,  'NoLMHash',                 1),          # no LM hash storage
    @($lsa,  'LmCompatibilityLevel',     5),          # NTLMv2 only, refuse LM & NTLM
    @("$lsa\MSV1_0", 'NTLMMinClientSec', $ntlmSec),   # NTLM SSP client minimums
    @("$lsa\MSV1_0", 'NTLMMinServerSec', $ntlmSec),   # NTLM SSP server minimums
    @("$pipe\AllowedExactPaths", 'Machine', $none),   # remote registry paths: none
    @("$pipe\AllowedPaths",      'Machine', $none),   # remote registry sub-paths: none
    @($srv,  'DisableCompression', [int]($SMBCompression -eq 'Disabled'))   # SMBGhost (CVE-2020-0796)
)

foreach ($s in $settings) {
    $path, $name = $s[0], $s[1]
    $value = $s[2]
    $kind  = if ($value -is [array]) { 'MultiString' } else { 'DWord' }
    Invoke-Step -Command "[Registry]::SetValue('$path', '$name', '$($value -join ',')', $kind)" -Action {
        [Microsoft.Win32.Registry]::SetValue($path, $name, $value, $kind)
    }
}

# Anonymous SID/Name translation has no registry value; it is a Local Security Policy (secedit) setting.
Invoke-Step -Command "secedit /configure /areas SECURITYPOLICY (LSAAnonymousNameLookup = 0)" -Action {
    $inf = Join-Path $env:TEMP 'smb_anon_lookup.inf'
    $sdb = Join-Path $env:TEMP 'smb_anon_lookup.sdb'
    try {
        @'
[Unicode]
Unicode=yes
[Version]
signature="$CHICAGO$"
Revision=1
[System Access]
LSAAnonymousNameLookup = 0
'@ | Set-Content -Path $inf -Encoding Unicode
        secedit /configure /db $sdb /cfg $inf /areas SECURITYPOLICY /quiet | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "secedit exited with code $LASTEXITCODE" }
    }
    finally { Remove-Item $inf, $sdb -Force -ErrorAction SilentlyContinue }
}

Write-Host "[+] SMB & file sharing hardening finished (any failures are listed in $ErrorLog)." -ForegroundColor Green