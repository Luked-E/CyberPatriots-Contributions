Import-Module -Name "EngineUtils.psd1" -Force
Assert-AdminPrivileges

# ==============================================================================
# CyberPatriot Windows Security Suite - Interactive Arrow-Key CLI Engine
# ==============================================================================

[Console]::CursorVisible = $false
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ManifestFile = Join-Path $ScriptDir "scripts_manifest.json"

if (-not (Test-Path $ManifestFile)) {
    Write-ErrorLog -Message "Manifest file not found at $ManifestFile"
    pause
    exit 1
}

$ManifestRaw = Get-Content -Raw -Path $ManifestFile
$Manifest = $ManifestRaw | ConvertFrom-Json

# Global Settings
$GlobalOS = $Manifest.default_windows_version
if ([string]::IsNullOrWhiteSpace($GlobalOS)) {
    $GlobalOS = "Windows 11"
}

# Queue Storage: Array of PSCustomObject with Id and OptValues hashtable
$script:ExecutionQueue = [System.Collections.ArrayList]@()

# Helper to deep copy options hashtable
function Copy-OptionValues {
    param($src)
    $dest = @{}
    if ($src) {
        foreach ($k in $src.Keys) {
            $dest[$k] = $src[$k]
        }
    }
    return $dest
}

# Flattens scripts for selection while remembering category
$AllScripts = @()
foreach ($cat in $Manifest.categories) {
    foreach ($scr in $cat.scripts) {
        $opts = @{}
        if ($scr.options) {
            foreach ($o in $scr.options) {
                $opts[$o.name] = $o.default
            }
        }
        $AllScripts += [PSCustomObject]@{
            Category    = $cat.category_name
            Id          = $scr.id
            Title       = $scr.title
            Description = $scr.description
            ScriptPath  = $scr.script_path
            OptionDefs  = $scr.options
            OptValues   = $opts
        }
    }
}

function Clear-ScreenBuffer {
    try {
        [Console]::Clear()
    } catch {
        Clear-Host
    }
}

# Render Header Banner
function Show-Header {
    param([string]$Subtitle)
    Clear-ScreenBuffer
    Write-Host "====================================================================================================" -ForegroundColor Cyan
    Write-Host "                       CYBERPATRIOT WINDOWS 11 SECURITY SUITE   " -ForegroundColor Yellow -NoNewline
    Write-Host " [v2.0]" -ForegroundColor DarkGray
    Write-Host " Target OS: " -NoNewline -ForegroundColor Gray
    Write-Host "$GlobalOS" -ForegroundColor Green -NoNewline
    Write-Host "  |  Queued Scripts: " -NoNewline -ForegroundColor Gray
    Write-Host "$($script:ExecutionQueue.Count)" -ForegroundColor Magenta
    Write-Host "====================================================================================================" -ForegroundColor Cyan
    if ($Subtitle) {
        Write-Host " $Subtitle" -ForegroundColor White
        Write-Host "----------------------------------------------------------------------------------------------------" -ForegroundColor DarkGray
    }
}

# Helper: Interactive Menu with Arrow Keys, Enter, Pagination, and Window Bounds
function Show-InteractiveMenu {
    param(
        [string]$Subtitle,
        [string[]]$MenuItems,
        [int]$DefaultIndex = 0,
        [string]$HelpText = "[Up/Down] Navigate  |  [Enter] Select  |  [Q/Esc] Back/Quit",
        [string]$ColumnHeader = ""
    )

    $selectedIndex = $DefaultIndex
    if ($selectedIndex -ge $MenuItems.Length) { $selectedIndex = 0 }
    if ($selectedIndex -lt 0) { $selectedIndex = 0 }

    # Window / Pagination calculation
    # Typical cmd window is 25-30 lines high. We allocate:
    # 7 lines (Header) + 2 lines (ColumnHeader) + 2 lines (Help & Spacing) = ~11 lines reserved.
    $winHeight = 25
    try {
        if ([Console]::WindowHeight -gt 15) {
            $winHeight = [Console]::WindowHeight
        }
    } catch {}

    $reservedLines = if ($ColumnHeader) { 12 } else { 10 }
    $maxVisible = [Math]::Max(6, $winHeight - $reservedLines)
    $viewStart = 0

    while ($true) {
        # Keep selected index in view
        if ($selectedIndex -eq 0) {
            $viewStart = 0
        } elseif ($selectedIndex -eq $MenuItems.Length - 1 ) {
            $viewStart = $MenuItems.Length - $(if($maxVisible -ge $MenuItems.Length) {$MenuItems.Length} else {$maxVisible})
        } elseif ($selectedIndex -le $viewStart) {
            $viewStart = $selectedIndex -1
        } elseif ($selectedIndex -ge $viewEnd) {
            $viewStart = $selectedIndex - $maxVisible + 2
        }
        $viewEnd = [Math]::Min($viewStart + $maxVisible -1, $MenuItems.Length - 1)

        Show-Header $Subtitle
        if ($ColumnHeader) {
            Write-Host "       $ColumnHeader" -ForegroundColor DarkYellow
            Write-Host "       $('-' * ($ColumnHeader.Length))" -ForegroundColor DarkGray
        }

        # Pagination upward indicator
        if ($selectedIndex -eq 0) {
            Write-Host "  -->  " -ForegroundColor Yellow -NoNewline
            Write-Host "$($MenuItems[0])" -ForegroundColor Black -BackgroundColor Yellow
        } elseif ($viewStart -eq 0) {
            Write-Host "       $($MenuItems[0])" -ForegroundColor Gray
        } elseif ($viewStart -gt 0) {
            Write-Host "  ...  [▲ $($viewStart + 1) more items above]" -ForegroundColor DarkCyan
        }

        for ($i = $viewStart + 1; $i -le $viewEnd -1; $i++) {
            if ($i -eq $selectedIndex) {
                Write-Host "  -->  " -ForegroundColor Yellow -NoNewline
                Write-Host "$($MenuItems[$i])" -ForegroundColor Black -BackgroundColor Yellow
            } else {
                Write-Host "       $($MenuItems[$i])" -ForegroundColor Gray
            }
        }

        # Pagination downward indicator
        if ($selectedIndex -eq ($MenuItems.Length - 1)) {
            Write-Host "  -->  " -ForegroundColor Yellow -NoNewline
            Write-Host "$($MenuItems[$MenuItems.Length - 1])" -ForegroundColor Black -BackgroundColor Yellow
        } elseif ($viewEnd -eq ($MenuItems.Length - 1)) {
            Write-Host "       $($MenuItems[$MenuItems.Length - 1])" -ForegroundColor Gray
        } elseif (($MenuItems.Length - 1) - $viewEnd -gt 0) {
            $remaining = $MenuItems.Length - $viewEnd
            Write-Host "  ...  [▼ $remaining more items below]" -ForegroundColor DarkCyan
        }

        Write-Host "$maxVisible - $selectedIndex, $viewStart - $viewEnd, "
        #Write-Host ""
        Write-Host "$HelpText" -ForegroundColor DarkCyan

        $key = [Console]::ReadKey($true)
        switch ($key.Key) {
            "UpArrow" {
                $selectedIndex--
                if ($selectedIndex -lt 0) { 
                    $selectedIndex = $MenuItems.Length - 1 
                }
            }
            "DownArrow" {
                $selectedIndex++
                if ($selectedIndex -ge $MenuItems.Length) { 
                    $selectedIndex = 0 
                }
            }
            "LeftArrow" {
                return -1
            }
            "RightArrow" {
                return $selectedIndex
            }
            "PageUp" {
                $selectedIndex = [Math]::Max(0, $selectedIndex - $maxVisible)
            }
            "PageDown" {
                $selectedIndex = [Math]::Min($MenuItems.Length - 1, $selectedIndex + $maxVisible)
            }
            "Home" {
                $selectedIndex = 0
            }
            "End" {
                $selectedIndex = $MenuItems.Length - 1
            }
            "Enter" {
                return $selectedIndex
            }
            "Escape" {
                return -1
            }
            "Q" {
                return -1
            }
        }
    }
}

# Submenu: Change Target Windows Version
function Select-WindowsVersion {
    $versions = @($Manifest.windows_versions)
    if ($versions.Count -eq 0) {
        $versions = @("Windows 11", "Windows 10", "Windows Server 2022", "Windows Server 2019", "Windows Server 2008")
    }
    $currIndex = 0
    for ($i = 0; $i -lt $versions.Count; $i++) {
        if ($versions[$i] -eq $GlobalOS) { $currIndex = $i; break }
    }

    $idx = Show-InteractiveMenu "Select Target Windows Version" $versions $currIndex "[Up/Down] Navigate  |  [Enter] Confirm OS  |  [Esc] Cancel"
    if ($idx -ge 0) {
        $script:GlobalOS = $versions[$idx]
    }
}

# Submenu: Configure Script Parameters & Options
function Configure-ScriptOptions {
    param(
        $scriptObj,
        $customOptValues = $null,
        [string]$ConfirmActionLabel = "Save and Return"
    )

    if (-not $scriptObj.OptionDefs -or $scriptObj.OptionDefs.Count -eq 0) {
        Show-Header "Configure Parameters: $($scriptObj.Title)"
        Write-Host "`n  This script enforces standard baseline security settings and has no optional flags." -ForegroundColor Yellow
        Write-Host "`n  Press any key to return..." -ForegroundColor Gray
        [Console]::ReadKey($true) | Out-Null
        return $true
    }

    $workingOpts = if ($customOptValues) { $customOptValues } else { $scriptObj.OptValues }

    $optIdx = 0
    while ($true) {
        $items = @()
        foreach ($od in $scriptObj.OptionDefs) {
            $val = $workingOpts[$od.name]
            $paddedName = $od.name.PadRight(22)
            $paddedVal = "[$val]".PadRight(12)
            $items += "$paddedName $paddedVal $($od.description)"
        }
        $items += "[$ConfirmActionLabel]"
        $items += "[Cancel]"

        $colHeader = "{0,-22} {1,-12} {2}" -f "Option Setting", "Value", "Description"
        $sel = Show-InteractiveMenu "Configure Flags: $($scriptObj.Title)" $items $optIdx "[Up/Down] Navigate  |  [Enter] Toggle Value / Confirm  |  [Esc] Cancel" $colHeader
        
        # User canceled via Esc or selecting [Cancel]
        if ($sel -eq -1 -or $sel -eq ($items.Length - 1)) {
            return $false
        }

        # User confirmed via [$ConfirmActionLabel]
        if ($sel -eq ($items.Length - 2)) {
            return $true
        }

        $optIdx = $sel
        $targetOpt = $scriptObj.OptionDefs[$optIdx]
        $optName = $targetOpt.name

        if ($targetOpt.type -eq "switch") {
            $workingOpts[$optName] = -not [bool]$workingOpts[$optName]
        } elseif ($targetOpt.type -eq "select") {
            $choices = @($targetOpt.choices)
            $curChoice = $workingOpts[$optName]
            $cIdx = [array]::IndexOf($choices, $curChoice)
            $cIdx = ($cIdx + 1) % $choices.Count
            $workingOpts[$optName] = $choices[$cIdx]
        }
    }
}

# Launch a Subscript
function Invoke-SubScript {
    param(
        $scriptObj,
        $customOpts = $null,
        $skipPressKey = $false
    )

    Show-Header "Launching: $($scriptObj.Title)"
    $resolvedPath = Join-Path $ScriptDir $scriptObj.ScriptPath
    $activeOpts = if ($customOpts) { $customOpts } else { $scriptObj.OptValues }

    # Build argument hashtable for proper parameter binding (Splatting)
    $argHash = @{
        WindowsVersion = $GlobalOS
    }
    
    if ($scriptObj.OptionDefs) {
        foreach ($od in $scriptObj.OptionDefs) {
            $val = $activeOpts[$od.name]
            if ($od.type -eq "switch") {
                if ($val -eq $true) {
                    # Strip leading hyphen from flag name if present (e.g. "-ScanProhibitedMedia" -> "ScanProhibitedMedia")
                    $paramName = $od.flag.TrimStart('-')
                    $argHash[$paramName] = $true
                }
            } elseif ($od.type -eq "select") {
                $paramName = $od.flag.TrimStart('-')
                $argHash[$paramName] = $val
            }
        }
    }

    # For display logging purposes
    $argListDisplay = $argHash.GetEnumerator() | ForEach-Object { "-$($_.Key) `"$($_.Value)`"" }

    Write-Host "`n  Script Path : $resolvedPath" -ForegroundColor Cyan
    Write-Host "  Arguments   : $($argListDisplay -join ' ')" -ForegroundColor Cyan
    Write-Host "----------------------------------------------------------------------------------------------------" -ForegroundColor DarkGray

    if (-not (Test-Path $resolvedPath)) {
        Write-Host "`n  [!] Subscript file not yet created: $resolvedPath" -ForegroundColor Yellow
        Write-Host "      (Subscripts will be implemented individually according to the master checklist.)" -ForegroundColor Gray
        Write-Host "`n  Command that will be invoked:" -ForegroundColor White
        Write-Host "  powershell.exe -ExecutionPolicy Bypass -File `"$resolvedPath`" $($argListDisplay -join ' ')" -ForegroundColor Green
    } else {
        $commandAttempted = "& `"$resolvedPath`" $($argListDisplay -join ' ')"
        try {
            & $resolvedPath @argHash
            if ($LASTEXITCODE -ne $null -and $LASTEXITCODE -ne 0) {
                Write-ErrorLog -Message "Script exited with non-zero exit code $LASTEXITCODE | Command: $commandAttempted" -ScriptName $scriptObj.ScriptPath
            } else {
                Write-Host "`n  [+] Execution completed with exit code: $LASTEXITCODE" -ForegroundColor Green
            }
        } catch {
            Write-ErrorLog -Message "Error executing script: $($_.Exception.Message) | Command: $commandAttempted" -ScriptName $scriptObj.ScriptPath
        }
    }

    if ($skipPressKey) {
        Start-Sleep -Seconds 2
    } else {
        Write-Host "`n----------------------------------------------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host "Press any key to return..." -ForegroundColor Yellow
        [Console]::ReadKey($true) | Out-Null
    }
    
}

# Queue Management Helpers
function Add-ScriptToQueue {
    param(
        $scriptObj,
        $optValues
    )
    $existingIndex = -1
    for ($i = 0; $i -lt $script:ExecutionQueue.Count; $i++) {
        if ($script:ExecutionQueue[$i].Id -eq $scriptObj.Id) {
            $existingIndex = $i
            break
        }
    }

    $qEntry = [PSCustomObject]@{
        Id        = $scriptObj.Id
        OptValues = (Copy-OptionValues $optValues)
    }

    if ($existingIndex -ge 0) {
        $script:ExecutionQueue[$existingIndex] = $qEntry
    } else {
        [void]$script:ExecutionQueue.Add($qEntry)
    }
}

function Remove-ScriptFromQueue {
    param([string]$scriptId)
    for ($i = $script:ExecutionQueue.Count - 1; $i -ge 0; $i--) {
        if ($script:ExecutionQueue[$i].Id -eq $scriptId) {
            $script:ExecutionQueue.RemoveAt($i)
            break
        }
    }
}

# Submenu: Prompt to Queue a Selected Script
function Prompt-QueueScript {
    param($scriptObj)

    $hasOptions = ($scriptObj.OptionDefs -and $scriptObj.OptionDefs.Count -gt 0)

    if (-not $hasOptions) {
        Add-ScriptToQueue $scriptObj $scriptObj.OptValues
        Show-Header "Script Queued: $($scriptObj.Title)"
        Write-Host "`n  [+] '$($scriptObj.Title)' has been added to the execution queue." -ForegroundColor Green
        Write-Host "      Baseline settings will be enforced with no extra arguments." -ForegroundColor Gray
        Start-Sleep -Milliseconds 350
        return $true
    }

    $choices = @(
        "Accept default configuration and queue",
        "Input custom configuration and queue",
        "Cancel"
    )

    $sel = Show-InteractiveMenu "Queue Script: $($scriptObj.Title)" $choices 0 "[Up/Down] Navigate  |  [Enter] Select  |  [Esc] Cancel"
    if ($sel -eq 0) {
        Add-ScriptToQueue $scriptObj $scriptObj.OptValues
        Show-Header "Script Queued: $($scriptObj.Title)"
        Write-Host "`n  [+] '$($scriptObj.Title)' queued with default arguments." -ForegroundColor Green
        Start-Sleep -Milliseconds 350
        return $true
    } elseif ($sel -eq 1) {
        $customOpts = Copy-OptionValues $scriptObj.OptValues
        Configure-ScriptOptions $scriptObj $customOpts "Save and Queue"
        Add-ScriptToQueue $scriptObj $customOpts
        Show-Header "Script Queued: $($scriptObj.Title)"
        Write-Host "`n  [+] '$($scriptObj.Title)' queued with customized arguments." -ForegroundColor Green
        Start-Sleep -Milliseconds 350
        return $true
    }
    return $false
}

# Submenu for an individual Subscript
function Show-SubscriptDetailMenu {
    param($scriptObj)

    $queuedScript = $false
    $menuIndex = 0
    while ($true) {
        $hasOptions = ($scriptObj.OptionDefs -and $scriptObj.OptionDefs.Count -gt 0)

        $isQueued = $false
        foreach ($qe in $script:ExecutionQueue) {
            if ($qe.Id -eq $scriptObj.Id) { $isQueued = $true; break }
        }
        $queueLabel = if ($isQueued) { "Queue Script for Batch Run [Currently Queued - Update/Reconfigure]" } else { "Queue Script for Batch Run" }

        $menuItems = @(
            $queueLabel,
            "Execute Subscript Now",
            "View Description & Details",
            "Back to Subscript List"
        )

        $subtitle = "$($scriptObj.Category) -> $($scriptObj.Title)"
        $choice = Show-InteractiveMenu $subtitle $menuItems $menuIndex

        if ($choice -eq -1 -or $choice -eq 3) {
            break
        }

        switch ($choice) {
            0 {
                $queuedScript = Prompt-QueueScript $scriptObj
            }
            1 {
                # Prompt user for run configuration/arguments before executing
                if ($hasOptions) {
                    $execChoices = @(
                        "Execute with default arguments",
                        "Input custom configuration and execute",
                        "Cancel"
                    )
                    $execSel = Show-InteractiveMenu "Execute: $($scriptObj.Title)" $execChoices 0 "[Up/Down] Navigate  |  [Enter] Select  |  [Esc] Cancel"
                    if ($execSel -eq 0) {
                        Invoke-SubScript $scriptObj $scriptObj.OptValues
                    } elseif ($execSel -eq 1) {
                        $customOpts = Copy-OptionValues $scriptObj.OptValues
                        $saved = Configure-ScriptOptions $scriptObj $customOpts "Save and Run"
                        if ($saved) {
                            Invoke-SubScript $scriptObj $customOpts
                        }
                    }
                } else {
                    Invoke-SubScript $scriptObj $scriptObj.OptValues
                }
            }
            2 {
                Show-Header "Details: $($scriptObj.Title)"
                Write-Host "`n  Category    : " -NoNewline -ForegroundColor Gray
                Write-Host "$($scriptObj.Category)" -ForegroundColor Cyan
                Write-Host "  Script ID   : " -NoNewline -ForegroundColor Gray
                Write-Host "$($scriptObj.Id)" -ForegroundColor Yellow
                Write-Host "  Script File : " -NoNewline -ForegroundColor Gray
                Write-Host "$($scriptObj.ScriptPath)" -ForegroundColor White
                Write-Host "`n  Description : " -NoNewline -ForegroundColor Gray
                Write-Host "$($scriptObj.Description)" -ForegroundColor White

                Write-Host "`n  Configured Options:" -ForegroundColor Gray
                if ($scriptObj.OptionDefs -and $scriptObj.OptionDefs.Count -gt 0) {
                    Write-Host ("      {0,-22} {1,-14} {2,-20} {3}" -f "Name", "Flag", "Current Value", "Description") -ForegroundColor DarkYellow
                    Write-Host ("      {0,-22} {1,-14} {2,-20} {3}" -f "----", "----", "-------------", "-----------") -ForegroundColor DarkGray
                    foreach ($od in $scriptObj.OptionDefs) {
                        Write-Host ("      {0,-22} {1,-14} {2,-20} {3}" -f $od.name, $od.flag, "[$($scriptObj.OptValues[$od.name])]", $od.description) -ForegroundColor Gray
                    }
                } else {
                    Write-Host "      [None] Standard security baseline enforced automatically without optional flags." -ForegroundColor DarkGreen
                }
                Write-Host "`n  Target Windows Version Passed : " -NoNewline -ForegroundColor Gray
                Write-Host "$GlobalOS" -ForegroundColor Green
                Write-Host "`n  Press any key to return..." -ForegroundColor Gray
                [Console]::ReadKey($true) | Out-Null
            }
        }
        $menuIndex = $choice
        if ($queuedScript) {
            break
        }
    }
}

# Submenu: Edit Queued Script Arguments or Remove
function Show-EditQueuedScriptMenu {
    param($qEntry)

    $targetScript = $null
    foreach ($s in $AllScripts) {
        if ($s.Id -eq $qEntry.Id) { $targetScript = $s; break }
    }
    if (-not $targetScript) { return }

    $mIdx = 0
    while ($true) {
        $items = @(
            "Edit Arguments for Queued Script",
            "Remove Script from Queue",
            "Back to Queue List"
        )

        $sel = Show-InteractiveMenu "Manage Queued Script: $($targetScript.Title)" $items $mIdx
        if ($sel -eq -1 -or $sel -eq 2) {
            break
        }

        switch ($sel) {
            0 {
                if ($targetScript.OptionDefs -and $targetScript.OptionDefs.Count -gt 0) {
                    Configure-ScriptOptions $targetScript $qEntry.OptValues "Save and Queue"
                } else {
                    Show-Header "Configure Parameters: $($targetScript.Title)"
                    Write-Host "`n  This baseline script does not have optional arguments." -ForegroundColor Yellow
                    Write-Host "`n  Press any key to return..." -ForegroundColor Gray
                    [Console]::ReadKey($true) | Out-Null
                }
            }
            1 {
                Remove-ScriptFromQueue $qEntry.Id
                Show-Header "Queue Updated"
                Write-Host "`n  [-] Removed '$($targetScript.Title)' from queue." -ForegroundColor Yellow
                Start-Sleep -Milliseconds 600
                return
            }
        }
        $mIdx = $sel
    }
}

# Submenu: Edit Queue List
function Show-EditQueueMenu {
    $qIdx = 0
    while ($true) {
        if ($script:ExecutionQueue.Count -eq 0) {
            Show-Header "Edit Execution Queue"
            Write-Host "`n  The execution queue is currently empty." -ForegroundColor Yellow
            Write-Host "  Select scripts from the master list to add them to the queue." -ForegroundColor Gray
            Write-Host "`n  Press any key to return..." -ForegroundColor DarkGray
            [Console]::ReadKey($true) | Out-Null
            return
        }

        $items = @()
        foreach ($qe in $script:ExecutionQueue) {
            $scr = $null
            foreach ($s in $AllScripts) {
                if ($s.Id -eq $qe.Id) { $scr = $s; break }
            }
            $tTitle = if ($scr) { $scr.Title } else { $qe.Id }
            $idCol = $qe.Id.PadRight(28)

            $argSummary = ""
            if ($scr.OptionDefs) {
                $argParts = @()
                foreach ($od in $scr.OptionDefs) {
                    $argParts += "$($od.name)=$($qe.OptValues[$od.name])"
                }
                $argSummary = $argParts -join ", "
            } else {
                $argSummary = "Baseline (Default)"
            }

            $items += "$idCol | $tTitle ($argSummary)"
        }
        $items += "[Execute All Queued Scripts Now]"
        $items += "[Clear All Scripts from Queue]"
        $items += "Back to Previous Menu"

        $colHeader = "{0,-28} | {1}" -f "Script ID", "Queued Script Title & Arguments"
        $sel = Show-InteractiveMenu "Edit Execution Queue ($($script:ExecutionQueue.Count) queued)" $items $qIdx "[Up/Down] Navigate  |  [Enter] Manage Script  |  [Esc] Back" $colHeader

        if ($sel -eq -1 -or $sel -eq ($items.Length - 1)) {
            break
        }

        if ($sel -eq ($items.Length - 3)) {
            Execute-QueuedScriptsDialog
            if ($script:ExecutionQueue.Count -eq 0) { break }
        } elseif ($sel -eq ($items.Length - 2)) {
            $script:ExecutionQueue.Clear()
            Show-Header "Queue Cleared"
            Write-Host "`n  [+] All scripts cleared from queue." -ForegroundColor Yellow
            Start-Sleep -Milliseconds 600
            break
        } else {
            $qIdx = $sel
            Show-EditQueuedScriptMenu $script:ExecutionQueue[$sel]
        }
    }
}

# Submenu: View All Subscripts in One List with Columns & Queue Count
function Show-AllScriptsMenu {
    $scrIndex = 0
    while ($true) {
        $items = @()
        foreach ($s in $AllScripts) {
            $idCol = $s.Id.PadRight(28)
            $optCount = if ($s.OptionDefs) { "$($s.OptionDefs.Count) opt(s)" } else { "Baseline" }
            $optCol = $optCount.PadRight(10)

            $isQueued = $false
            foreach ($qe in $script:ExecutionQueue) {
                if ($qe.Id -eq $s.Id) { $isQueued = $true; break }
            }
            $qTag = if ($isQueued) { "[QUEUED]" } else { "        " }

            $items += "$idCol | $optCol | $qTag | $($s.Title)"
        }

        $editQueueLabel = "Edit Queue ($($script:ExecutionQueue.Count) scripts queued)"
        $items += $editQueueLabel
        $items += "Back to Main Menu"

        $colHeader = "{0,-28} | {1,-10} | {2,-8} | {3}" -f "Script ID", "Config", "Status", "Subscript Title"
        $subtitle = "All Checklist Subscripts ($($AllScripts.Count) Total)  --  [Queued: $($script:ExecutionQueue.Count)]"
        $sel = Show-InteractiveMenu $subtitle $items $scrIndex "[Up/Down] Navigate  |  [Enter] Select Subscript  |  [Esc] Back" $colHeader

        if ($sel -eq -1 -or $sel -eq ($items.Length - 1)) {
            break
        }

        if ($sel -eq ($items.Length - 2)) {
            Show-EditQueueMenu
        } else {
            $scrIndex = $sel
            Show-SubscriptDetailMenu $AllScripts[$sel]
        }
    }
}

# Submenu: Execute Queued Scripts Dialog
function Execute-QueuedScriptsDialog {
    if ($script:ExecutionQueue.Count -eq 0) {
        Show-Header "Execute Queued Scripts"
        Write-Host "`n  The execution queue is currently empty." -ForegroundColor Yellow
        Write-Host "  Queue scripts first via the Master List or 'Run All Checklist Scripts in Sequence'." -ForegroundColor Gray
        Write-Host "`n  Press any key to return..." -ForegroundColor DarkGray
        [Console]::ReadKey($true) | Out-Null
        return
    }

    Show-Header "Execute Queued Scripts"
    Write-Host "`n  Ready to execute $($script:ExecutionQueue.Count) queued scripts." -ForegroundColor Yellow
    Write-Host "  Target OS: $GlobalOS" -ForegroundColor Green
    Write-Host "`n  Scripts in queue:" -ForegroundColor Cyan

    $i = 1
    foreach ($qe in $script:ExecutionQueue) {
        $scr = $null
        foreach ($s in $AllScripts) {
            if ($s.Id -eq $qe.Id) { $scr = $s; break }
        }
        $title = if ($scr) { $scr.Title } else { $qe.Id }
        Write-Host "   $i. [$($qe.Id)] $title" -ForegroundColor Gray
        $i++
    }

    Write-Host "`n  Press [Enter] to begin execution, or [Esc] to cancel..." -ForegroundColor White
    $key = [Console]::ReadKey($true)
    if (-not ($key.Key -eq "Enter" -or $key.Key -eq [System.ConsoleKey]::RightArrow)) {
        return
    }

    $idx = 0
    foreach ($qe in @($script:ExecutionQueue)) {
        $idx++
        $scr = $null
        foreach ($s in $AllScripts) {
            if ($s.Id -eq $qe.Id) { $scr = $s; break }
        }
        if ($scr) {
            Write-Host "`n[$idx/$($script:ExecutionQueue.Count)] Executing: $($scr.Title)..." -ForegroundColor Yellow
            Invoke-SubScript $scr $qe.OptValues $true
        }
    }

    Write-Host "`n[+] Completed execution of all queued scripts." -ForegroundColor Green
    Write-Host "Press any key to return..." -ForegroundColor Gray
    [Console]::ReadKey($true) | Out-Null
}

# Interactive Wizard: Queue All Checklist Scripts with Walkthrough
function Queue-AllScriptsWizard {
    Show-Header "Queue All Checklist Scripts Wizard"
    Write-Host "`n  This walkthrough will guide you through all $($AllScripts.Count) checklist scripts." -ForegroundColor Yellow
    Write-Host "  For each script, select whether to queue it with default arguments, custom arguments," -ForegroundColor Gray
    Write-Host "  or skip it." -ForegroundColor Gray
    Write-Host "`n  Target OS: $GlobalOS" -ForegroundColor Green
    Write-Host "`n  Press [Enter] to start walkthrough, or [Esc] to cancel..." -ForegroundColor White

    $key = [Console]::ReadKey($true)
    if ($key.Key -ne "Enter") {
        return
    }

    $step = 0
    foreach ($scr in $AllScripts) {
        $step++
        $hasOptions = ($scr.OptionDefs -and $scr.OptionDefs.Count -gt 0)

        if ($hasOptions) {
            $wChoices = @(
                "Run with default arguments",
                "Run with custom arguments",
                "Do not run this script (skip)"
            )
        } else {
            $wChoices = @(
                "Run with default arguments",
                "Do not run this script (skip)"
            )
        }

        $promptTitle = "Wizard [$step/$($AllScripts.Count)]: $($scr.Title)"
        $wSel = Show-InteractiveMenu $promptTitle $wChoices 0 "[Up/Down] Navigate  |  [Enter] Select  |  [Esc] Cancel Wizard"

        if ($wSel -eq -1) {
            Show-Header "Wizard Canceled"
            Write-Host "`n  Wizard paused. Preserved scripts currently added to queue ($($script:ExecutionQueue.Count) total)." -ForegroundColor Yellow
            Start-Sleep -Milliseconds 800
            return
        }

        if ($hasOptions) {
            switch ($wSel) {
                0 {
                    Add-ScriptToQueue $scr $scr.OptValues
                }
                1 {
                    $customOpts = Copy-OptionValues $scr.OptValues
                    Configure-ScriptOptions $scr $customOpts "Save and Queue"
                    Add-ScriptToQueue $scr $customOpts
                }
                2 {
                    # Skip
                }
            }
        } else {
            switch ($wSel) {
                0 {
                    Add-ScriptToQueue $scr $scr.OptValues
                }
                1 {
                    # Skip
                }
            }
        }
    }

    Show-Header "Wizard Complete"
    Write-Host "`n  [+] Walkthrough complete! Total scripts in queue: $($script:ExecutionQueue.Count)" -ForegroundColor Green
    Write-Host "`n  Press any key to view the master list..." -ForegroundColor Gray
    [Console]::ReadKey($true) | Out-Null
}

# ==============================================================================
# Main Program Loop
# ==============================================================================
$mainMenuIndex = 0
try {
    while ($true) {
        $mainMenuItems = @(
            "View Full Subscript Master List ($($AllScripts.Count) scripts in columns)",
            "Run All Checklist Scripts in Sequence (Queue All Walkthrough)",
            "Execute Queued Scripts ($($script:ExecutionQueue.Count) ready)",
            "Change Target Windows Version (Current: $GlobalOS)",
            "Exit Suite"
        )

        $choice = Show-InteractiveMenu "Main Menu - Select an Option" $mainMenuItems $mainMenuIndex
        if ($choice -eq -1 -or $choice -eq 4) {
            
            Write-Host "Exiting CyberPatriot SUITE. Good luck!" -ForegroundColor Green
            breakClear-ScreenBuffer
        }

        switch ($choice) {
            0 { Show-AllScriptsMenu }
            1 { Queue-AllScriptsWizard }
            2 { Execute-QueuedScriptsDialog }
            3 { Select-WindowsVersion }
        }
        $mainMenuIndex = $choice
    }
} finally {
    [Console]::CursorVisible = $true
}