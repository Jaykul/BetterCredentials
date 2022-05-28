function Set-Credential {
    <#
        .Synopsis
            Creates or updates a stored credential
        .Description
            Set-Credential is a wrapper around the Windows Authentication API's CredWrite
            It allows you to store a credential in Windows Credential Manager (Vault) with metadata attached
        .Example
            Set-Credential Jaykul@HuddledMasses.org

        .Link
            Find-Credential
        .Link
            Get-Credential
        .Link
            https://msdn.microsoft.com/en-us/library/windows/desktop/aa375187
        .Link
            https://msdn.microsoft.com/en-us/library/windows/desktop/aa374788
     #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password", Justification = "Let other people worry about that, this is a useful option")]
    [Alias('scred')]
    [CmdletBinding()]
    param(
        # A credential to store
        [Parameter(ValueFromPipeline, Mandatory)]
        [PSCredential]$Credential,

        # The unique target string to identify the credential
        [string]$Target,

        # How to store the credential ("Generic" or "DomainPassword")
        # NOTE: DomainPassword only works on Windows, and will bypass SecretManagement
        [BetterCredentials.CredentialType]$Type = "Generic",

        # Where to store the credential ("Session", "LocalComputer", "Enterprise")
        # NOTE: Only applies when bypassing SecretManagement
        [BetterCredentials.PersistenceType]$Persistence = "LocalComputer",

        # Some text to describe or further identify the credentials
        [Alias("Message")]
        [string]$Description,

        # If set, the value of $Target will be passed to the CredWrite API without any modification
        # Depending on the configuration of your Secret Vault, this may make the credential invisible to the Vault
        [switch]$ForceTarget
    )
    process {
        $Metadata = @{}

        if ($ForceTarget) {
            $Credential | Add-Member NoteProperty ForceTarget $Target -Force
        }
        # If the user passed the value, or if it's not set
        if ($PSBoundParameters.ContainsKey("Type") -or !$Credential.Type) {
            $Credential | Add-Member NoteProperty Type $Type -Force
            $Metadata["Type"] = $Type
        }

        if ($PSBoundParameters.ContainsKey("Persistence") -or !$Credential.Persistence) {
            $Credential | Add-Member NoteProperty Persistence $Persistence -Force
            $Metadata["Persistence"] = $Persistence
        }

        if ($PSBoundParameters.ContainsKey("Description")) {
            $Credential | Add-Member NoteProperty Description $Description -Force
            $Metadata["Description"] = $Description
        }

        if (!$Target -and $Credential.UserName) {
            $Target = "$(if ($Credential.Domain) {"$($Credential.Domain)\" })$($Credential.UserName)"
        }

        & $script:ImplementationModule\Set-Secret -Name $Target -Secret $Credential @BetterCredentialsSecretManagementParameters

        if ($Metadata) {
            & $script:ImplementationModule\Set-SecretInfo -Name $Target -Metadata $Metadata @BetterCredentialsSecretManagementParameters
        }
    }
}