[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$WindowsVersion = "Windows 11"
)

$ParentDir = [System.IO.Directory]::GetParent($PSScriptRoot).FullName
Import-Module -Name "$ParentDir\EngineUtils.psd1" -Force
Assert-AdminPrivileges

$ErrorActionPreference = 'Stop'

Write-Host "[*] Applying Task Scheduler hardening for $WindowsVersion..." -ForegroundColor Cyan

# --- Scheduled tasks: list non-Microsoft tasks, disable those with suspicious indicators ---
$Suspicious = '(?i)\\AppData\\Local\\Temp|\\Windows\\Temp|%TEMP%|%TMP%|\s-enc(odedcommand)?\s|-w(indowstyle)?\s+hidden|\.(bat|cmd)\b|wscript\.exe'

# Invoke-Step discards action output, so query results are stored in script-scoped variables
$Tasks = @()
Invoke-Step "Get-ScheduledTask (non-Microsoft/Apple)" {
    $script:Tasks = Get-ScheduledTask | Where-Object { $_.TaskPath -notlike "\Microsoft*" -and $_.TaskPath -notlike "\Apple*" }
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
    Invoke-Step "Disable-ScheduledTask -TaskName '$($r.TaskName)' -TaskPath '$($r.TaskPath)'" {
        Disable-ScheduledTask -TaskName $r.TaskName -TaskPath $r.TaskPath
    }
}

# --- WMI event subscription persistence ---
$Ns        = "root\subscription"
$Filters   = @()
$Consumers = @()
$Bindings  = @()
Invoke-Step "Get-CimInstance $Ns __EventFilter" { $script:Filters = Get-CimInstance -Namespace $Ns -ClassName __EventFilter }
Invoke-Step "Get-CimInstance $Ns CommandLineEventConsumer" { $script:Consumers = Get-CimInstance -Namespace $Ns -ClassName CommandLineEventConsumer }
Invoke-Step "Get-CimInstance $Ns __FilterToConsumerBinding" { $script:Bindings = Get-CimInstance -Namespace $Ns -ClassName __FilterToConsumerBinding }

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
    Invoke-Step "Remove-CimInstance $($obj.CimClass.CimClassName) '$id'" {
        Remove-CimInstance -InputObject $obj
    }
}

Write-Host "[+] Task Scheduler hardening applied. Any errors were logged to the Logs directory." -ForegroundColor Green