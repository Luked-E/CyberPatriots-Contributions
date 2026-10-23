[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$WindowsVersion = "Windows 11"
)

# ---------------------------------------------------------------------------
# GLOBAL CONSTANTS & SCRIPT STATE
# ---------------------------------------------------------------------------
$ErrorActionPreference = 'Stop'

# Dynamic determination of root orchestrator directory vs local script folder
$BaseDir = if ((Split-Path -Leaf $PSScriptRoot) -eq "Sub_Scripts") { 
    Split-Path -Parent $PSScriptRoot 
} else { 
    if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path } 
}

# Define and ensure the Logs directory exists
$LogDir = Join-Path $BaseDir "Logs"
if (-not (Test-Path -LiteralPath $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

$ScriptName = Get-PSCallStack

# Set the dynamic log file path: {script name}_{current date}.log
$CurrentDate = Get-Date -Format "yyyy-MM-dd"
$script:LogPath = Join-Path $LogDir "ScriptEngine_${CurrentDate}.log"

# ---------------------------------------------------------------------------
# CORE ERROR LOGGING FUNCTION
# ---------------------------------------------------------------------------
function Write-ErrorLog {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [string]$ScriptName = (Get-PSCallStack)[0].Command
    )

    Write-Host "    [!] $Message" -ForegroundColor Red
    $logLine = "{0} [ERROR] [{1}] [{2}] {3}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $ScriptName, $WindowsVersion, $Message
    
    try {
        Add-Content -LiteralPath $script:LogPath -Value $logLine -Encoding UTF8 -ErrorAction Stop
    }
    catch {
        Write-Host "    [!] Could not write to log file ($script:LogPath): $($_.Exception.Message)" -ForegroundColor Red
    }
}
function Write-WarningLog {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [string]$ScriptName = (Get-PSCallStack)[0].Command
    )

    Write-Host "    [!] $Message" -ForegroundColor Red
    $logLine = "{0} [Warning] [{1}] [{2}] {3}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $ScriptName, $WindowsVersion, $Message
    
    try {
        Add-Content -LiteralPath $script:LogPath -Value $logLine -Encoding UTF8 -ErrorAction Stop
    }
    catch {
        Write-Host "    [!] Could not write to log file ($script:LogPath): $($_.Exception.Message)" -ForegroundColor Red
    }
}

# ---------------------------------------------------------------------------
# ADMINISTRATIVE ELEVATION CHECK
# ---------------------------------------------------------------------------
function Assert-AdminPrivileges {
    param(
        [Parameter(Mandatory = $false)]
        [switch]$Silent
    )

    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$identity
    $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin -and -not $Silent) {
        if (Get-Command Write-ErrorLog -ErrorAction SilentlyContinue) {
            Write-ErrorLog -Message "Execution failed: Script must be run with elevated Administrator privileges."
        } else {
            Write-Host "    [!] Execution failed: Script must be run with elevated Administrator privileges." -ForegroundColor Red
        }
        throw "Administrator privileges required."
    }

    return $isAdmin
}

# ---------------------------------------------------------------------------
# EXECUTION WRAPPER
# ---------------------------------------------------------------------------
function Invoke-Step {
    param(
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$Command,

        [Parameter(Mandatory = $true, Position = 1)]
        [scriptblock]$Action
    )

    # If Command string was omitted, extract the textual scriptblock representation
    if ([string]::IsNullOrWhiteSpace($Command)) {
        $Command = $Action.ToString().Trim()
    }

    try {
        $global:LASTEXITCODE = 0
        & $Action | Out-Null
        if ($LASTEXITCODE -ne 0) { 
            throw "Process exited with non-zero exit code: $LASTEXITCODE" 
        }
        Write-Host "[+] $Command" -ForegroundColor Green
    }
    catch {
        Write-ErrorLog -Message "$Command | $($_.Exception.Message)"
        Write-Host "[-] Failed: $Command" -ForegroundColor Red
    }
}

# ---------------------------------------------------------------------------
# REGISTRY WRAPPER
# ---------------------------------------------------------------------------
function Set-RegValue {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Name,

        [Parameter(Mandatory = $true, Position = 2)]
        $Value,

        [Parameter(Mandatory = $false, Position = 3)]
        [ValidateSet("DWord", "String", "QWord", "Binary", "MultiString", "ExpandString")]
        [string]$Type = "DWord"
    )

    $cmdText = "Set-RegValue: Path='$Path', Name='$Name', Value='$Value', Type='$Type'"

    Invoke-Step -Command $cmdText -Action {
        if (-not (Test-Path -LiteralPath $Path)) {
            $logMessage = "[$(Get-Date -Format s)] Key Created: $Path"
            Write-WarningLog -message $logMessage
        }

        $netPath = $Path -replace '^HKLM:\\?', 'HKEY_LOCAL_MACHINE\' -replace '^HKCU:\\?', 'HKEY_CURRENT_USER\'
        
        $valueKind = switch ($Type) {
            "DWord"        { [Microsoft.Win32.RegistryValueKind]::DWord }
            "QWord"        { [Microsoft.Win32.RegistryValueKind]::QWord }
            "String"       { [Microsoft.Win32.RegistryValueKind]::String }
            "Binary"       { [Microsoft.Win32.RegistryValueKind]::Binary }
            "MultiString"  { [Microsoft.Win32.RegistryValueKind]::MultiString }
            "ExpandString" { [Microsoft.Win32.RegistryValueKind]::ExpandString }
            default        { [Microsoft.Win32.RegistryValueKind]::DWord }
        }

        $typedValue = switch ($Type) {
            "DWord"  { [int]$Value }
            "QWord"  { [long]$Value }
            default  { $Value }
        }

        [Microsoft.Win32.Registry]::SetValue($netPath, $Name, $typedValue, $valueKind)
    }
}