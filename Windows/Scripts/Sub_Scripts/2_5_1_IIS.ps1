[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$WindowsVersion = "Windows 11",

    [Parameter(Mandatory = $false)]
    [ValidateSet("Disabled", "Enabled")]
    [string]$IISState = "Disabled"
)

$ParentDir = [System.IO.Directory]::GetParent($PSScriptRoot).FullName
Import-Module -Name "$ParentDir\EngineUtils.psd1" -Force
Assert-AdminPrivileges

Write-Host "[*] Applying IIS hardening for $WindowsVersion (IIS: $IISState)..." -ForegroundColor Cyan

$ErrorActionPreference = 'Stop'
$AppHost   = 'MACHINE/WEBROOT/APPHOST'
$SystemSid = '*S-1-5-18'
$AdminsSid = '*S-1-5-32-544'
# Remove inherited ACEs; leave only SYSTEM and Administrators with Full Control
$LockDown  = @('/inheritance:r', '/grant:r', "${SystemSid}:(OI)(CI)F", "${AdminsSid}:(OI)(CI)F")

function Get-IISAuth([string]$Site, [string]$Provider) {
    Get-WebConfiguration -PSPath $AppHost -Location $Site -Filter "system.webServer/security/authentication/$Provider" -ErrorAction SilentlyContinue
}

# Adds a denied entry (verb / file extension) to a request filtering collection if not already present
function Add-IISDeny([string]$Filter, [string]$Attr, [string[]]$Names) {
    foreach ($n in $Names) {
        Invoke-Step -Action {
            if (-not (Get-WebConfiguration -PSPath $AppHost -Filter "$Filter/add[@$Attr='$n']")) {
                Add-WebConfigurationProperty -PSPath $AppHost -Filter $Filter -Name '.' -Value @{ $Attr = $n; allowed = 'False' }
            }
        }
    }
}

if ($IISState -eq 'Disabled') {
    if (Get-Service -Name 'W3SVC' -ErrorAction SilentlyContinue) {
        Invoke-Step -Action { Stop-Service -Name 'W3SVC' -Force; Set-Service -Name 'W3SVC' -StartupType Disabled }
    }
}
elseif (Get-Service -Name 'W3SVC' -ErrorAction SilentlyContinue) {
    Invoke-Step -Action { Import-Module WebAdministration }

    if (Get-Module WebAdministration) {
        $sites = @(Get-Website)

        # Bindings: only ports 80 and 443
        foreach ($site in $sites) {
            foreach ($b in @($site.Bindings.Collection)) {
                $port = [regex]::Match($b.bindingInformation, ':(\d+):[^:]*$').Groups[1].Value
                if ($b.protocol -in 'http', 'https' -and $port -notin '80', '443') {
                    Invoke-Step -Action { Remove-WebBinding -Name $site.Name -BindingInformation $b.bindingInformation -Protocol $b.protocol }
                }
            }
        }

        # Logging: W3C format with required fields, log directory restricted to Administrators and SYSTEM
        $logFilter = 'system.applicationHost/sites/siteDefaults/logFile'
        Invoke-Step -Action { Set-WebConfigurationProperty -PSPath $AppHost -Filter $logFilter -Name logFormat -Value 'W3C' }
        Invoke-Step -Action { Set-WebConfigurationProperty -PSPath $AppHost -Filter $logFilter -Name logExtFileFlags -Value 'Date,Time,ClientIP,UserName,SiteName,ServerIP,Method,UriStem,UriQuery,HttpStatus,Win32Status,UserAgent,Referer,Host,ServerPort' }
        Invoke-Step -Action {
            $logDir = [Environment]::ExpandEnvironmentVariables((Get-WebConfiguration -PSPath $AppHost -Filter $logFilter).directory)
            if (Test-Path -LiteralPath $logDir) { icacls $logDir @LockDown | Out-Null }
        }

        # Default placeholder content and sample virtual directories
        foreach ($f in @(Get-ChildItem "$env:SystemDrive\inetpub\wwwroot\iisstart.*" -ErrorAction SilentlyContinue)) {
            Invoke-Step -Action { Remove-Item -LiteralPath $f.FullName -Force }
        }
        foreach ($site in $sites) {
            foreach ($vdir in 'IISHelp', 'MSADC', 'IISSamples') {
                if (Get-WebVirtualDirectory -Site $site.Name -Name $vdir -ErrorAction SilentlyContinue) {
                    Invoke-Step -Action { Remove-WebVirtualDirectory -Site $site.Name -Name $vdir }
                }
            }
        }

        # Per-site authentication hardening
        foreach ($site in $sites) {
            $anon = Get-IISAuth $site.Name 'anonymousAuthentication'
            if ($anon.enabled -and $anon.userName) {
                Invoke-Step -Action { icacls ([Environment]::ExpandEnvironmentVariables($site.physicalPath)) /deny "$($anon.userName):(OI)(CI)(W,DC)" | Out-Null }
            }
            if ((Get-IISAuth $site.Name 'basicAuthentication').enabled) {
                Invoke-Step -Action { Set-WebConfigurationProperty -PSPath $AppHost -Location $site.Name -Filter 'system.webServer/security/access' -Name sslFlags -Value 'Ssl' }
            }
            if ((Get-IISAuth $site.Name 'windowsAuthentication').enabled -and ($site.Bindings.Collection.protocol -contains 'https')) {
                Invoke-Step -Action { Set-WebConfigurationProperty -PSPath $AppHost -Location $site.Name -Filter 'system.webServer/security/authentication/windowsAuthentication/extendedProtection' -Name tokenChecking -Value 'Require' }
            }
        }

        # ISAPI filters whose binary is missing
        foreach ($f in @(Get-WebConfiguration -PSPath $AppHost -Filter 'system.webServer/isapiFilters/filter')) {
            if (-not ($f.path -and (Test-Path -LiteralPath ([Environment]::ExpandEnvironmentVariables($f.path))))) {
                Invoke-Step -Action { Remove-WebConfigurationProperty -PSPath $AppHost -Filter 'system.webServer/isapiFilters' -Name '.' -AtElement @{ name = $f.name } }
            }
        }

        # Legacy handler mappings
        foreach ($h in @(Get-WebConfiguration -PSPath $AppHost -Filter 'system.webServer/handlers/add' | Where-Object { $_.path -in '*.asp', '*.asa', '*.cer', '*.cdx' })) {
            Invoke-Step -Action { Remove-WebConfigurationProperty -PSPath $AppHost -Filter 'system.webServer/handlers' -Name '.' -AtElement @{ name = $h.name } }
        }

        # WebDAV authoring rules
        if (Get-WebConfiguration -PSPath $AppHost -Filter 'system.webServer/webdav/authoringRules/*' -ErrorAction SilentlyContinue) {
            Invoke-Step -Action { Clear-WebConfiguration -PSPath $AppHost -Filter 'system.webServer/webdav/authoringRules' }
        }

        # Application pools must not run as LocalSystem or Administrator
        foreach ($pool in @(Get-ChildItem IIS:\AppPools)) {
            $m = $pool.processModel
            if ($m.identityType -eq 'LocalSystem' -or ($m.identityType -eq 'SpecificUser' -and $m.userName -match '(^|\\)Administrator$')) {
                Invoke-Step -Action { Set-ItemProperty "IIS:\AppPools\$($pool.Name)" -Name processModel.identityType -Value 'ApplicationPoolIdentity' }
            }
        }

        # Request filtering (server level, inherited by all sites)
        Add-IISDeny 'system.webServer/security/requestFiltering/verbs' 'verb' 'TRACE', 'TRACK', 'DEBUG'
        Add-IISDeny 'system.webServer/security/requestFiltering/fileExtensions' 'fileExtension' '.bak', '.inc', '.old', '.sql', '.config'

        # Security response headers
        $headers = [ordered]@{
            'X-Frame-Options'           = 'SAMEORIGIN'
            'X-Content-Type-Options'    = 'nosniff'
            'Strict-Transport-Security' = 'max-age=31536000; includeSubDomains'
        }
        $hdrFilter = 'system.webServer/httpProtocol/customHeaders'
        foreach ($h in $headers.GetEnumerator()) {
            Invoke-Step -Action {
                if (Get-WebConfiguration -PSPath $AppHost -Filter "$hdrFilter/add[@name='$($h.Key)']") {
                    Set-WebConfigurationProperty -PSPath $AppHost -Filter "$hdrFilter/add[@name='$($h.Key)']" -Name value -Value $h.Value
                } else {
                    Add-WebConfigurationProperty -PSPath $AppHost -Filter $hdrFilter -Name '.' -Value @{ name = $h.Key; value = $h.Value }
                }
            }
        }
    }

    # IIS 6 metabase compatibility
    Invoke-Step -Action {
        if ((Get-WindowsOptionalFeature -Online -FeatureName 'IIS-Metabase').State -eq 'Enabled') {
            Disable-WindowsOptionalFeature -Online -FeatureName 'IIS-Metabase' -NoRestart | Out-Null
        }
    }
}

Write-Host "[+] IIS hardening applied. Any failures are logged to the Logs folder." -ForegroundColor Green
