@{

    # Script module or binary module file associated with this manifest.
    RootModule           = 'BetterCredentials.Extension.psm1'

    # Version number of this module.
    ModuleVersion        = '1.0'

    # ID used to uniquely identify this module
    GUID                 = 'da628277-368d-4b6b-a513-8e3b8fc76f0e'

    # Author of this module
    Author               = 'Joel Bennett'

    # Company or vendor of this module
    CompanyName          = 'HuddledMasses.org'

    # Copyright statement for this module
    Copyright            = '(c) 2022 Joel Bennett. All rights reserved.'

    # Description of the functionality provided by this module
    Description          = 'An extension for Microsoft.PowerShell.SecretManagement to expose the Windows Credential Manager'

    # Minimum version of the Windows PowerShell engine required by this module
    # PowerShellVersion = '5.1'

    RequiredModules      = @()
    RequiredAssemblies   = @()
    ScriptsToProcess     = @()
    TypesToProcess       = @()
    FormatsToProcess     = @()
    NestedModules        = @()
    CmdletsToExport      = @()
    VariablesToExport    = @()
    DscResourcesToExport = @()

    # Functions to export from this module
    FunctionsToExport    = 'Get-Secret', 'Get-SecretInfo', 'Set-Secret', 'Set-SecretInfo', 'Remove-Secret', 'Test-SecretVault'
    AliasesToExport      = @()

    FileList             = @('BetterCredentials.cs', 'BetterCredentials.Extension.psm1')
}