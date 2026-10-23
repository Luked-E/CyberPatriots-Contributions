@{
    RootModule = 'EngineUtils.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'a1b2c3d4-e5f6-7890-abcd-ef0123456789'
    Author = 'Administrator'
    CompanyName = 'Unknown'
    Copyright = '(c) All rights reserved.'
    Description = 'Module manifest for system hardening and registry utility functions.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Write-ErrorLog',
        'Write-WarningLog',
        'Assert-AdminPrivileges',
        'Invoke-Step',
        'Set-RegValue'
    )
    CmdletsToExport = @()
    VariablesToExport = '*'
    AliasesToExport = @()
}