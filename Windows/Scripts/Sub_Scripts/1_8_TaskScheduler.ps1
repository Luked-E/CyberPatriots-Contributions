[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$WindowsVersion = "Windows 11"
)

$ScriptName = $MyInvocation.MyCommand.Name
$ErrorLog   = Join-Path (Get-Location).Path "errors.log"

# Runs an action; on failure logs file name + command attempted to errors.log in the current directory.
function Invoke-Safe {
    param([string]$Command, [scriptblock]$Action)
    try {
        $ErrorActionPreference = "Stop"
        & $Action
    } catch {
        Add-Content -Path $ErrorLog -Value "[$(Get-Date -Format s)] File: $ScriptName | Command: $Command | Error: $($_.Exception.Message)"
        Write-Host "[!] Failed: $Command - $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "[*] Applying Task Scheduler hardening for $WindowsVersion..." -ForegroundColor Cyan

# --- Scheduled tasks: list non-Microsoft tasks, disable those with suspicious indicators ---
$Suspicious = '(?i)\\AppData\\Local\\Temp|\\Windows\\Temp|%TEMP%|%TMP%|\s-enc(odedcommand)?\s|-w(indowstyle)?\s+hidden|\.(bat|cmd)\b|wscript\.exe'

$Tasks = Invoke-Safe "Get-ScheduledTask (non-Microsoft/Apple)" {
    Get-ScheduledTask | Where-Object { $_.TaskPath -notlike "\Microsoft*" -and $_.TaskPath -notlike "\Apple*" }
}

$Rows = foreach ($t in $Tasks) {
    [pscustomobject]@{
        TaskName = $t.TaskName
        TaskPath = $t.TaskPath
        State    = $t.State
        Command  = ($t.Actions | ForEach-Object { "$($_.Execute) $($_.Arguments)".Trim() }) -join "; "
    }
}
$Rows | Format-Table -AutoSize -Wrap | Out-Host

foreach ($r in $Rows | Where-Object { $_.Command -match $Suspicious -and $_.State -ne "Disabled" }) {
    Invoke-Safe "Disable-ScheduledTask -TaskName '$($r.TaskName)' -TaskPath '$($r.TaskPath)'" {
        Disable-ScheduledTask -TaskName $r.TaskName -TaskPath $r.TaskPath | Out-Null
        Write-Host "[+] Disabled suspicious task: $($r.TaskPath)$($r.TaskName)" -ForegroundColor Green
    }
}

# --- WMI event subscription persistence ---
$Ns        = "root\subscription"
$Filters   = Invoke-Safe "Get-CimInstance $Ns __EventFilter" { Get-CimInstance -Namespace $Ns -ClassName __EventFilter }
$Consumers = Invoke-Safe "Get-CimInstance $Ns CommandLineEventConsumer" { Get-CimInstance -Namespace $Ns -ClassName CommandLineEventConsumer }
$Bindings  = Invoke-Safe "Get-CimInstance $Ns __FilterToConsumerBinding" { Get-CimInstance -Namespace $Ns -ClassName __FilterToConsumerBinding }

Write-Host "=== WMI Event Filters ===" -ForegroundColor Yellow
$Filters | Select-Object Name, Query | Format-Table -AutoSize -Wrap | Out-Host
Write-Host "=== WMI Command Line Consumers ===" -ForegroundColor Yellow
$Consumers | Select-Object Name, CommandLineTemplate, ExecutablePath | Format-Table -AutoSize -Wrap | Out-Host
Write-Host "=== WMI Filter To Consumer Bindings ===" -ForegroundColor Yellow
$Bindings | Select-Object @{N="Filter";E={$_.Filter.Name}}, @{N="Consumer";E={$_.Consumer.Name}} | Format-Table -AutoSize | Out-Host

$BadConsumers = @($Consumers | Where-Object { $_.Name -like "*malicious*" -or $_.CommandLineTemplate -like "*powershell*" })
$BadFilters   = @($Filters   | Where-Object { $_.Name -like "*malicious*" })
$BadBindings  = @($Bindings  | Where-Object { $_.Consumer.Name -in $BadConsumers.Name -or $_.Filter.Name -in $BadFilters.Name })

# Bindings first so no orphaned bindings remain after the consumer/filter are removed
foreach ($obj in $BadBindings + $BadConsumers + $BadFilters) {
    $id = if ($obj.Name) { $obj.Name } else { "$($obj.Filter.Name) -> $($obj.Consumer.Name)" }
    Invoke-Safe "Remove-CimInstance $($obj.CimClass.CimClassName) '$id'" {
        Remove-CimInstance -InputObject $obj
        Write-Host "[+] Removed $($obj.CimClass.CimClassName): $id" -ForegroundColor Green
    }
}

Write-Host "[+] Task Scheduler hardening applied. Errors (if any) logged to $ErrorLog" -ForegroundColor Green