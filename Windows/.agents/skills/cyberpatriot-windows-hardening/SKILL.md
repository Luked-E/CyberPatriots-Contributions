---
name: cyberpatriot-windows-hardening
description: Guide and generate Windows security scripts, parameter structures, and manifest entries for CyberPatriot Windows Security Orchestrator. Use when writing PowerShell subscripts, configuring security settings, or registering new scripts in scripts_manifest.json.
---

# CyberPatriot Windows Security Orchestrator & Subscript Guide

Use this skill to design, write, and integrate compliant PowerShell security scripts and manifest configurations for the CyberPatriot Windows Security Orchestrator architecture.

## Architecture Overview

The orchestrator uses a declarative JSON manifest (`scripts_manifest.json`) to drive an interactive Terminal User Interface (TUI), passing structured CLI parameters to modular PowerShell scripts under `Sub_Scripts\`.

```text
Windows/Scripts/
├── Master_SecLauncher.bat    # Elevated entry point launcher
├── Engine.ps1                # Interactive TUI, argument mapper & execution engine
├── scripts_manifest.json     # Declarative registry of scripts, categories & arguments
└── Sub_Scripts/              # Modular security PowerShell scripts (.ps1)
```

---

## 1. Subscript Parameter Rules

Every subscript **must** accept the universal `-WindowsVersion` parameter and any specific options defined in the manifest.

### Universal Parameter
* **`-WindowsVersion`**: Always passed as a string (e.g., `"Windows 11"`, `"Windows Server 2022"`). Use this for OS-specific branching (e.g., registry keys).

### Standard Baseline Script Template (No Options)
Use this template for scripts that enforce standard security baselines unconditionally:

```powershell
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$WindowsVersion = "Windows 11"
)

Write-Host "[*] Applying security hardening for $WindowsVersion..." -ForegroundColor Cyan

# Place hardening commands here (Registry, Policies, Services)

Write-Host "[+] Hardening applied successfully." -ForegroundColor Green
```

### Configurable Feature Script Template (With Options)
Use this template for features that require toggle states (e.g., Enabled/Disabled):

```powershell
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$WindowsVersion = "Windows 11",

    [Parameter(Mandatory = $false)]
    [ValidateSet("Disabled", "Enabled")]
    [string]$FeatureState = "Disabled"
)

Write-Host "[*] Configuring feature for $WindowsVersion (Target State: $FeatureState)..." -ForegroundColor Cyan

if ($FeatureState -eq "Disabled") {
    # Actions for disabled state
    Write-Host "[+] Feature has been disabled." -ForegroundColor Green
} else {
    # Actions for enabled state
    Write-Host "[+] Feature has been enabled." -ForegroundColor Yellow
}
```

---

## 2. Registering Scripts in `scripts_manifest.json`

Add new scripts to the manifest schema so the engine can parse options and render them in the TUI.

### Schema Structure
```json
{
  "id": "unique_string_id",
  "title": "Display Title for Menu",
  "description": "Short explanation of security actions performed.",
  "script_path": "Sub_Scripts\\Sec_ScriptName.ps1",
  "options": []
}
```

### Option Types
1. **Select (`"type": "select"`)**: Renders a choice toggle in the TUI menu.
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
2. **Switch (`"type": "switch"`)**: Renders a boolean toggle (`true` / `false`). When `true`, passes the flag.
   ```json
   {
     "name": "ScanMediaFiles",
     "flag": "-ScanProhibitedMedia",
     "type": "switch",
     "default": true,
     "description": "Scan and report unauthorized files"
   }
   ```
