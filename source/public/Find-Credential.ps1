function Find-Credential {
    <#
        .Synopsis
            Searches stored credentials

        .Description
            Find-Credential is a wrapper around CredEnumerate
            It allows you to retrieve some or all credentials stored by BetterCredentials

            As of 5.0 it uses Get-SecretInfo if SkipSecretManagement isn't set

        .Example
            Find-Credential

            Returns all the stored BetterCredentials for the user
        .Example
            Find-Credential User@Example.org

            Filters credentials stored by BetterCredentials for User@Example.org
    #>
    [Alias('fdcred')]
    [CmdletBinding()]
    param(
        # A filter for the Target name. May contain an asterisk wildcard at the start OR at the end.
        [Alias("Target")]
        [String]$Filter = "*"
    )

    & $script:ImplementationModule\Get-SecretInfo $Filter @BetterCredentialsSecretManagementParameters |
        & $script:ImplementationModule\Get-Secret @BetterCredentialsSecretManagementParameters
}