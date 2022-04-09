function Get-Secret {
    [CmdletBinding()]
    param (
        [string] $Name,
        [string] $VaultName,
        [hashtable] $AdditionalParameters
    )
    $Prefix = "$($AdditionalParameters.Prefix)"
    $Name = "$Prefix$Name"

    $Credential = [BetterCredentials.Store]::Load($Name, "Generic")

    $Type, $Description = $Credential.Description -Split " ", 2

    switch ($Type) {
        "string" {
            $Credential.Password
        }
        "ByteArray" {
            [Convert]::FromBase64String($Credential.GetNetworkCredential().Password)
        }
        "SecureString" {
            $Credential.Password
        }
        "Hashtable" {
            if (Get-Command ConvertFrom-Json -ParameterName AsHashtable -ErrorAction Ignore) {
                $Credential.GetNetworkCredential().Password | ConvertFrom-Json -AsHashtable
            } else {
                Write-Warning "Hashtable secrets are not supported on this version of PowerShell"
                $Credential.GetNetworkCredential().Password | ConvertFrom-Json
            }
        }
        "Unknown" {
            $Credential.GetNetworkCredential().Password | ConvertFrom-Json
        }
        # PSCredential and credentials that we didn't put in there ...
        default {
            $Credential
        }
    }
}
