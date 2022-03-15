function Register-BetterCredentialVault {
    <#
        .SYNOPSIS
            Register a SecretManagement vault using our Credential Manager provider, and set it as the vault for the BetterCredentials commands.
        .EXAMPLE
            Register-BetterCredentialVault -Name MyVault -ResourceGroupName MyResourceGroup
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(<#Rule#>'PSAvoidUsingPlainTextForPassword',<#Parameter#>'CredentialPrefix', Justification = 'Not a credential parameter')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(<#Rule#>'PSShouldProcess')]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The name of the vault to register. Defaults to 'BetterCredentials'.
        [Alias('VaultName')]
        [switch]$Name = 'BetterCredentials',

        # A prefix to prepend to all secret names.
        #
        # Because BetterCredentials isn't the only thing putting credentials in the Credential Manager vault,
        # in order to be able to separate just the credentials created through BetterCredentials, we need a prefix.
        # The default is "MicrosoftPowerShell:user="
        # To disable this prefix and see all credentials through this vault, set this parameter to an empty string.
        [AllowEmptyString()]
        [string]$CredentialPrefix = "MicrosoftPowerShell:user=",

        # A description that is included in the vault registry information.
        [string]$Description,

        # Allows overwriting an existing registered extension vault with the same name.
        [switch]$AllowClobber,

        # Make the new extension vault the default vault for the current user.
        [switch]$DefaultVault,

        # Pass through the SecretVaultInfo object if it's successfully registered.
        [switch]$PassThru
    )

    $null = $PSBoundParameters.Remove("CredentialPrefix")

    Register-SecretVault -ModuleName BetterCredentials -VaultParameters @{ Prefix = $CredentialPrefix } @PSBoundParameters
    $Script:SecretVaultName = $Name
}