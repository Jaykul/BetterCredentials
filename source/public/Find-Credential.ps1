function Find-Credential {
    <#
        .Synopsis
            Searches stored credentials

        .Description
            Find-Credential is a wrapper around CredEnumerate
            It allows you to retrieve some or all credentials from the Windows Credential Manager (Vault)

        .Example
            Find-Credential

            Returns all the stored BetterCredentials for the user
        .Example
            Find-Credential User@Example.org

            Filters credentials stored by BetterCredentials for User@Example.org (where the Target is: 'MicrosoftPowerShell:user=User@Example.org')
        .Example
            Find-Credential -AllCredentials

            Returns all the stored Windows credentials for the user (including BetterCredentials)
        .Example
            Find-Credential TERMSRV/* -AllCredentials

            Returns all the credentials stored for Windows' Remote Desktop client
        .Notes
            History:
            v 5.0 Added the AllCredentials switch. If you don't set it, you're only searching credentials added by this module
    #>
    [Alias('fdcred')]
    [CmdletBinding()]
    param(
        # A filter for the Target name. May contain an asterisk wildcard at the start OR at the end.
        [Alias("Target")]
        [String]$Filter,

        # When -AllCredentials is set, the filter is passed directly to the Windows API
        # Otherwise, the filter matches Get-Credential's Target parameter:
        # If it has no ':' or '=' in it, it's prefixed with 'MicrosoftPowerShell:user='
        # If it has an '=' in it, it's prefixed with 'MicrosoftPowerShell:'
        [switch]$AllCredentials
    )
    if (!$AllCredentials -and !$Filter) {
        $Filter = "*"
    }
    [CredentialManagement.Store]::Find($Filter, !$AllCredentials)
}