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
        [string]$Target
    )

    process {
        & $script:ImplementationModule\Remove-Secret -Name $Target @BetterCredentialsSecretManagementParameters
    }
}