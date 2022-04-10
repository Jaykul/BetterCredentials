function Set-BetterCredentialsOption {
    <#
        .SYNOPSIS
            Since BetterCredentials 5 now supports SecretManagement, we have a few options.
        .DESCRIPTION
            BetterCredentials options allow you to avoid SecretManagement, be compatible with older versions, or filter the credentials from other vaults.

            If you need backward compatibility with older versions of BetterCredentials, register a secret vault with three overrides:

            PS C:\> Register-SecretVault -Name CredentialManager -ModuleName BetterCredentials -VaultParameters @{
                Namespace = "MicrosoftPowerShell"
                VaultName = "user"
                Separator  = "="
            }

        .EXAMPLE
            Set-BetterCredentialsOption -SkipSecretManagement

            Allows you to work only with the Windows Credential Vault, and skip SecretManagement

        .EXAMPLE
            Set-BetterCredentialsOption -VaultName CredentialManager

            Allows you to specify a single specific SecretManagement Vault for BetterCredentials to use.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(<#Rule#>'PSAvoidUsingPlainTextForPassword',<#Parameter#>'CredentialPrefix', Justification = 'Not a credential parameter')]
    [CmdletBinding()]
    param(
        # The name of the SecretVault to store credentials in.
        # By default, all secret vaults will be searched, and secrets will be stored in your default secret vault.
        # If you specify a name here, BetterCredentials will use that vault for saving, and will only search that vault.
        [Alias("Name")]
        [string]$VaultName,

        # A prefix to prepend to all secret names.
        # If you're storing credentials in a secret vault, you can use this to create a sort-of namespace for your credentials.
        # For compatibility with BetterCredentials 4.5 you could set this to "WindowsPowerShell:user="
        [AllowEmptyString()]
        [string]$CredentialPrefix,

        # Windows Only: if set, BetterCredentials will skip using SecretManagement.
        # If $IsMacOS or $IsLinux, this is ignored.
        [switch]$SkipSecretManagement
    )
    if ($PSBoundParameters.ContainsKey("SkipSecretManagement")) {
        $Script:SkipSecretManagement = [bool]$SkipSecretManagement
        if ($Script:SkipSecretManagement -and -not $IsLinux -and -not $IsMacOS) {
            $ImplementationModule = "BetterCredentials.Extension"
            Import-Module $PSScriptRoot\BetterCredentials.Extension\BetterCredentials.Extension.psd1
        } else {
            $ImplementationModule = "Microsoft.PowerShell.SecretManagement"
            Import-Module $ImplementationModule
        }
    }

    if ($PSBoundParameters.ContainsKey("SecretVaultName")) {
        $Script:BetterCredentialsSecretManagementParameters = @{
            Vault = $VaultName
        }
    }
    if ($PSBoundParameters.ContainsKey("CredentialPrefix")) {
        $Script:CredentialPrefix = $CredentialPrefix
    }
}

$Script:BetterCredentialsSecretManagementParameters = @{}
$CredentialPrefix = ""
Set-BetterCredentialsOption -SkipSecretManagement:(@(Get-Module "Microsoft.PowerShell.SecretManagement" -ListAvailable).Count -gt 0)
