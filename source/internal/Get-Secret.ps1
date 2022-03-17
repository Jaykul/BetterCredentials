function Get-Secret {
    [CmdletBinding()]
    param (
        [string] $Name,
        [string] $VaultName,
        [hashtable] $AdditionalParameters
    )
    $Name = $AdditionalParameters["Prefix"] + $Name

    $Credential = [BetterCredentials.Store]::Load($Name, "Generic")

    $Type, $Description = $Credential.Description -Split " ", 2

    switch ($Type) {
        "string" {
            $Credential.Password
        }
        "byte[]" {
            [Convert]::FromBase64String($Credential.GetNetworkCredential().Password)
        }
        "SecureString" {
            $Credential.Password
        }
        "Hashtable" {
            $Credential.GetNetworkCredential().Password | ConvertFrom-Json
        }
        "Unknown" {
            $Credential.GetNetworkCredential().Password | ConvertFrom-Json
        }
        # PSCredential and credentials that we didn't put in there ...
        default: {
            $Credential
        }
    }
}
