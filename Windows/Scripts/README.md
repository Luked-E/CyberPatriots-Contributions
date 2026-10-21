# CyberPatriot Windows Security Orchestrator - Developer & Subscript Guide

This guide documents the architecture of the CyberPatriot Windows Security Orchestrator, detailing how subscripts receive arguments, how to write compliant PowerShell subscripts, and how to register new scripts and configuration options in `scripts_manifest.json`.

---

## Table of Contents
1. [Overview & Directory Structure](#1-overview--directory-structure)
2. [How Arguments Are Handed to Subscripts](#2-how-arguments-are-handed-to-subscripts)
3. [Writing a Compatible Subscript File](#3-writing-a-compatible-subscript-file)
   - [Standard Baseline Script (No Options)](#standard-baseline-script-no-options)
   - [Configurable Feature Script (With Options)](#configurable-feature-script-with-options)
4. [Adding New Scripts to `scripts_manifest.json`](#4-adding-new-scripts-to-scripts_manifestjson)
   - [Schema Definition](#schema-definition)
   - [Option Types & Definitions](#option-types--definitions)
   - [Step-by-Step Example](#step-by-step-example)
5. [Orchestrator Execution Lifecycle](#5-orchestrator-execution-lifecycle)

---

## 1. Overview & Directory Structure

The system uses a declarative JSON manifest to drive an interactive Terminal User Interface (TUI), passing structured CLI parameters to modular PowerShell scripts:

```text
Windows/Scripts/
│
├── Master_SecLauncher.bat    # Elevated entry point launcher
├── Engine.ps1                # Interactive TUI, argument mapper & execution engine
├── scripts_manifest.json     # Declarative registry of scripts, categories & arguments
├── README.md                 # This documentation file
│
└── Sub_Scripts/              # Modular security PowerShell scripts (.ps1)
    ├── Sec_SettingsApp.ps1
    ├── Sec_RemoteDesktop.ps1
    └── ...
```

---

## 2. How Arguments Are Handed to Subscripts

When a subscript is executed (either individually or as part of a batch/queue run), [`Engine.ps1`](Engine.ps1) resolves the relative path to `Sub_Scripts\` and passes arguments as standard PowerShell parameters via dynamic splatting / argument arrays.

### Universal Parameter: `-WindowsVersion`
**Every subscript is always passed the `-WindowsVersion` parameter.**
- Passed as: `-WindowsVersion "<SelectedVersion>"`
- Example values: `"Windows 11"`, `"Windows 10"`, `"Windows Server 2022"`, `"Windows Server 2019"`, `"Windows Server 2008"`
- Allows subscripts to execute OS-specific branches (e.g. registry keys unique to Windows 11 vs Server 2022).

### Optional Parameters (Configurable Scripts)
For scripts with configurable feature options (such as RDP, SMTP, or network protocols), arguments are passed according to their `flag` defined in the manifest:

| Manifest Option Type | Manifest Flag Example | User Choice | Exact Argument Passed to Subscript |
| :--- | :--- | :--- | :--- |
| **`select`** | `-RDPState` | `"Disabled"` | `-RDPState "Disabled"` |
| **`select`** | `-RDPState` | `"Enabled"` | `-RDPState "Enabled"` |
| **`switch`** | `-EnforceSigning` | `true` | `-EnforceSigning` |
| **`switch`** | `-EnforceSigning` | `false` | *(Flag omitted entirely)* |

#### Complete Invocation Example
If the user selects target OS `Windows 11` and sets RDP state to `Disabled`:
```powershell
powershell.exe -ExecutionPolicy Bypass -File "Sub_Scripts\Sec_RemoteDesktop.ps1" -WindowsVersion "Windows 11" -RDPState "Disabled"
```

---

## 3. Writing a Compatible Subscript File

Subscripts must use a `param(...)` block at the very top of the script matching the expected arguments.

### Standard Baseline Script (No Options)
Standard computer hardening tasks (e.g., Settings App, UAC maximum, Local Security Policy) require no user options; standard hardening is always enforced. They only need to accept `-WindowsVersion`:

```powershell
# Sub_Scripts/Sec_SettingsApp.ps1
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$WindowsVersion = "Windows 11"
)

Write-Host "[*] Applying baseline Settings App hardening for $WindowsVersion..." -ForegroundColor Cyan

# 1. Disable AutoPlay for all drives
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers" -Name "DisableAutoplay" -Value 1 -Type DWord

# 2. Disable Lock Screen Notifications
if (-not (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System")) {
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Force | Out-Null
}
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "DisableLockScreenAppNotifications" -Value 1 -Type DWord

Write-Host "[+] Settings App hardening applied successfully." -ForegroundColor Green
```

### Configurable Feature Script (With Options)
Scripts managing services or roles that may need to be enabled or disabled depending on the competition README must accept the parameters configured in `scripts_manifest.json`:

```powershell
# Sub_Scripts/Sec_RemoteDesktop.ps1
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$WindowsVersion = "Windows 11",

    [Parameter(Mandatory = $false)]
    [ValidateSet("Disabled", "Enabled")]
    [string]$RDPState = "Disabled"
)

Write-Host "[*] Configuring Remote Desktop for $WindowsVersion (Target State: $RDPState)..." -ForegroundColor Cyan

$fDenyTSConnections = if ($RDPState -eq "Disabled") { 1 } else { 0 }

# Configure Terminal Server Connections
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value $fDenyTSConnections -Type DWord

if ($RDPState -eq "Disabled") {
    Stop-Service -Name "TermService" -Force -ErrorAction SilentlyContinue
    Set-Service -Name "TermService" -StartupType Disabled
    Write-Host "[+] Remote Desktop has been disabled." -ForegroundColor Green
} else {
    # If enabled, enforce Network Level Authentication (NLA)
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "UserAuthentication" -Value 1 -Type DWord
    Set-Service -Name "TermService" -StartupType Automatic
    Start-Service -Name "TermService" -ErrorAction SilentlyContinue
    Write-Host "[+] Remote Desktop enabled with Network Level Authentication (NLA) enforced." -ForegroundColor Yellow
}
```

---

## 4. Adding New Scripts to `scripts_manifest.json`

The manifest file [`scripts_manifest.json`](scripts_manifest.json) controls what the TUI displays and how arguments are mapped.

### Schema Definition

Each script entry in the `scripts` array has the following structure:

```json
{
  "id": "unique_string_id",
  "title": "Display Title for Menu",
  "description": "Short explanation of security actions performed.",
  "script_path": "Sub_Scripts\\Sec_ScriptName.ps1",
  "options": []
}
```

### Option Types & Definitions

The `options` array can be empty (`[]`) for non-configurable scripts, or contain one or more configuration objects:

#### 1. Select Option (`"type": "select"`)
Renders a toggleable choice in the configuration menu (e.g. `Disabled` vs `Enabled`):
```json
{
  "name": "RDPState",
  "flag": "-RDPState",
  "type": "select",
  "choices": ["Disabled", "Enabled"],
  "default": "Disabled",
  "description": "Remote Desktop feature state"
}
```

#### 2. Switch Option (`"type": "switch"`)
Renders a boolean `true` / `false` toggle. When `true`, passes the switch flag to the script:
```json
{
  "name": "ScanMediaFiles",
  "flag": "-ScanProhibitedMedia",
  "type": "switch",
  "default": true,
  "description": "Scan and report unauthorized video and audio files"
}
```

### Step-by-Step Example

To add a new script that manages Windows Defender Firewall rules:

1. **Create the Script**: Create `Sub_Scripts\Sec_FirewallCustom.ps1` with the appropriate `param(...)` block.
2. **Open `scripts_manifest.json`**.
3. **Add the Script Object** under the appropriate category in the `scripts` array:

```json
{
  "id": "firewall_advanced",
  "title": "Windows Firewall Rules & Logging",
  "description": "Configures firewall inbound/outbound logging and drops unsolicited incoming packets.",
  "script_path": "Sub_Scripts\\Sec_FirewallCustom.ps1",
  "options": [
    {
      "name": "FirewallLoggingState",
      "flag": "-FirewallLoggingState",
      "type": "select",
      "choices": ["Disabled", "Enabled"],
      "default": "Enabled",
      "description": "Log dropped packets in pfirewall.log"
    }
  ]
}
```

4. **Launch the Orchestrator**: The new script will immediately appear in the Master List, automatically support queueing, and pass `-FirewallLoggingState "Enabled"` to your script.

---

## 5. Orchestrator Execution Lifecycle

1. **Launch**: `Master_SecLauncher.bat` checks for administrator privileges and launches `Engine.ps1` with `-ExecutionPolicy Bypass`.
2. **Manifest Loading**: `Engine.ps1` deserializes `scripts_manifest.json` and loads the active Windows Version and script definitions into memory.
3. **Queueing & Direct Execution**:
   - Users browse the master list and select a script.
   - The primary options are:
     - `Queue Script for Batch Run`: Queues the script to be run in batch.
     - `Execute Subscript Now`: Prompts the user directly for run configuration/arguments (`Execute with default arguments`, `Input custom configuration and execute`, or `Cancel`). If custom configuration is selected, the options screen displays `[Save and Run]` and `[Cancel]`.
     - `View Description & Details`: Displays a summary of the script and its arguments.
   - For baseline scripts without options, both queueing and immediate execution run seamlessly using the standard security baseline.
   - The walkthrough wizard (`Queue All Walkthrough`) allows reviewing and queueing all scripts in sequence.
4. **Execution**:
   - `Invoke-SubScript` resolves the subscript path in `Sub_Scripts\`.
   - If the `.ps1` file does not yet exist on disk, the engine safely displays the resolved command string and arguments without crashing.
   - When the file exists, it runs directly within the elevated PowerShell session and displays exit code feedback.
