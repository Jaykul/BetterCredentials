function Test-Credential {
    <#
        .Synopsis
            Tests whether or not a credential with the given username exists in the credential vault.
        .Description
            The Test-Credential function returns a true value if a credential with the given username exists in your credential vault. If it does exist, you can use the Get-Credential function with the assurance that it will not prompt for credentials.

            Calling Test-Credential prior to Get-Credential prevents prompting the user for the credentials when the credential does not already exist in the credential store. This is useful for trapping errors in scripts that need to run unattended, and prevents Get-Credential from causing the execution of such scripts to hang.
        .Example
            Test-Credential UserName

            If you haven't stored the password for "UserName", Test-Credential returns a false value but does not prompt for the password. Otherwise it returns a true value.
        .Example
            Test-Credential UserName*

            A trailing asterisk is a wildcard character that matches zero or more characters at the end of the given user name.

        .Example
            Test-Credential *

            An asterisk alone as the value of the UserName parameter returns true if there are any credentials in the credential vault that were placed there by BetterCredentials.

        .Example
            Test-Credential ''

            An empty string value of the UserName parameter returns true if there are any credentials in the credential vault at all, whether or not placed there by BetterCredentials.

        .Notes
            History:
            v 4.4 Test-Credential added to BetterCredentials
            v 4.5 Changed to be based on Find
            v 5.0 Added the AllCredentials switch. If you don't set it, you're only searching/testing credentials added by this module
    #>
    [Alias('tcred')]
    [CmdletBinding()]
    [OutputType("System.Boolean")]
    param(
        [Parameter(Position = 1, Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias("Credential")]
        [PSObject]$UserName,

        # Include all credentials, rather than just the MicrosoftPowerShell: credentials (created by BetterCredentials)
        [switch]$AllCredentials
    )
    process {
        if ($UserName -is [System.Management.Automation.PSCredential]) {
            $target = $UserName.UserName
        } else {
            $target = $UserName.ToString()
        }
        return [CredentialManagement.Store]::Find($target, !$AllCredentials).Count -gt 0
    }
}