function Remove-Credential {
    <#
        .SYNOPSIS
            Remove a credential from the Windows Credential Manager (Vault)

        .DESCRIPTION
            Removes the credential for the specified target
    #>
    [Alias('rcred')]
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipelineByPropertyName, ValueFromPipeline, Mandatory)]
        [string]$Target,

        # How to store the credential ("Generic" or "DomainPassword")
        [Parameter(ValueFromPipelineByPropertyName)]
        [BetterCredentials.CredentialType]$Type = "Generic"
    )

    process {
        [BetterCredentials.Store]::Delete($Target, $Type, $false)
    }

}