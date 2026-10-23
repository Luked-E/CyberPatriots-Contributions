[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$WindowsVersion = "Windows 11",

    [Parameter(Mandatory = $false)]
    [ValidateSet("Disabled", "Enabled")]
    [string]$SMTPState = "Disabled"
)

$ParentDir = [System.IO.Directory]::GetParent($PSScriptRoot).FullName
Import-Module -Name "$ParentDir\EngineUtils.psd1" -Force
Assert-AdminPrivileges

$ErrorActionPreference = 'Stop'
$IsServer   = $WindowsVersion -like "*Server*"
$FwRuleName = "CP - Block SMTP TCP 25"

Write-Host "[*] Configuring SMTP for $WindowsVersion (Target State: $SMTPState)..." -ForegroundColor Cyan

$smtp = Get-Service -Name SMTPSVC -ErrorAction SilentlyContinue
$blockRule = Get-NetFirewallRule -DisplayName $FwRuleName -ErrorAction SilentlyContinue

if ($SMTPState -eq "Disabled") {
    if ($smtp) {
        Invoke-Step "Stop-Service SMTPSVC" { Stop-Service -Name SMTPSVC -Force -ErrorAction Stop }
        Invoke-Step "Set-Service SMTPSVC -StartupType Disabled" { Set-Service -Name SMTPSVC -StartupType Disabled -ErrorAction Stop }
    }
    # Windows 11 has no SMTP Server feature; only Windows Server can remove it.
    if ($IsServer -and (Get-WindowsFeature -Name SMTP-Server -ErrorAction SilentlyContinue).Installed) {
        Invoke-Step "Uninstall-WindowsFeature SMTP-Server" { Uninstall-WindowsFeature -Name SMTP-Server -ErrorAction Stop | Out-Null }
    }
    if (-not $blockRule) {
        Invoke-Step "New-NetFirewallRule Block TCP 25 Inbound" {
            New-NetFirewallRule -DisplayName $FwRuleName -Direction Inbound -Protocol TCP -LocalPort 25 `
                -Action Block -Profile Any -ErrorAction Stop | Out-Null
        }
    }
    Write-Host "[+] SMTP disabled and TCP 25 blocked." -ForegroundColor Green
    return
}

# --- Enabled: SMTP is required, so harden it (all hardening values are fixed) ---
if ($blockRule) {
    Invoke-Step "Remove-NetFirewallRule $FwRuleName" { Remove-NetFirewallRule -DisplayName $FwRuleName -ErrorAction Stop }
}
if (-not $smtp -and $IsServer) {
    Invoke-Step "Install-WindowsFeature SMTP-Server" { Install-WindowsFeature -Name SMTP-Server -ErrorAction Stop | Out-Null }
    $smtp = Get-Service -Name SMTPSVC -ErrorAction SilentlyContinue
}
if (-not $smtp) {
    Write-Host "[!] SMTPSVC is not present on $WindowsVersion; nothing to configure." -ForegroundColor Yellow
    return
}

$badMail = Join-Path $env:ProgramData "SMTP\BadMail"
Invoke-Step "New-Item $badMail" { New-Item -Path $badMail -ItemType Directory -Force -ErrorAction Stop | Out-Null }

$vs = [ADSI]"IIS://localhost/SmtpSvc/1"

# Relay: "Only the list below" containing only 127.0.0.1; authenticated users may not relay.
Invoke-Step "Set RelayIpList (GrantByDefault=false, IPGrant=127.0.0.1)" {
    $acl = $vs.Get("RelayIpList")
    $t = $acl.GetType()
    $t.InvokeMember("GrantByDefault", "SetProperty", $null, $acl, @($false))
    $t.InvokeMember("IPGrant", "SetProperty", $null, $acl, @(, @("127.0.0.1")))
    $vs.Put("RelayIpList", $acl)
}

# Property names below follow the IIS 6 metabase; each is logged individually if rejected.
$settings = [ordered]@{
    RelayForAuth     = 0                                         # uncheck "allow authenticated to relay"
    AuthFlags        = 4                                         # Integrated Windows auth only, no anonymous/basic
    SmtpUseSSL       = 1                                         # TLS inbound
    SmtpOutboundSSL  = 1                                         # TLS outbound
    SmtpEnableVrfy   = 0                                         # VRFY off
    SmtpEnableExpn   = 0                                         # EXPN off
    LogType          = 1                                         # logging on
    LogPluginClsid   = "{FF160663-DE82-11CF-BC0A-00AA006111E0}"  # W3C extended format
    LogExtFileFlags  = 0x7FFFFF                                  # all W3C fields (verbose)
    BadMailDirectory = $badMail
}
foreach ($name in $settings.Keys) {
    Invoke-Step "IIS://localhost/SmtpSvc/1 Put $name=$($settings[$name])" { $vs.Put($name, $settings[$name]) }
}
Invoke-Step "IIS://localhost/SmtpSvc/1 SetInfo" { $vs.SetInfo() }

Invoke-Step "Set-Service SMTPSVC -StartupType Automatic" { Set-Service -Name SMTPSVC -StartupType Automatic -ErrorAction Stop }
Invoke-Step "Restart-Service SMTPSVC" { Restart-Service -Name SMTPSVC -Force -ErrorAction Stop }

Write-Host "[+] SMTP hardened (relay restricted, no anonymous, TLS, W3C logging, VRFY/EXPN off)." -ForegroundColor Yellow