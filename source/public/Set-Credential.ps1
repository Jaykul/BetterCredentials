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
        [BetterCredentials.CredentialType]$Type = "Generic",

        # Where to store the credential ("Session", "LocalComputer", "Enterprise")
        [BetterCredentials.PersistanceType]$Persistence = "LocalComputer",

        # Some text to describe or further identify the credentials
        [Alias("Message")]
        [string]$Description
    )
    process {
        # Weird validation rules:
        if ($Type -eq "DomainPassword") {
            if ($Target.Length -gt 337) {
                throw "Target name must be less than 337 characters long for domain credentials"
            }
        }

        if ($Credential.Password.Length -gt 256) {
            # Because it's stored as UTF-16 bytes with a max of 512
            throw "Credential Password cannot be more than 256 characters"
        }

        if ($Target) {
            $Credential | Add-Member NoteProperty Target $Target -Force
        }
        if ($Description) {
            $Credential | Add-Member NoteProperty Description $Description -Force
        }

        # If the user passed the value, or if it's not set
        if ($PSBoundParameters.ContainsKey("Type") -or !$Credential.Type) {
            $Credential | Add-Member NoteProperty Type $Type -Force
        }

        if ($PSBoundParameters.ContainsKey("Persistence") -or !$Credential.Persistence) {
            $Credential | Add-Member NoteProperty Persistence $Persistence
        }

        [BetterCredentials.Store]::Save($Credential)
    }
}