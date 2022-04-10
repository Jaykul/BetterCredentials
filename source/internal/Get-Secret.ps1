function Get-Secret {
    [CmdletBinding()]
    param (
        [string] $Name,
        [string] $VaultName,
        [hashtable] $AdditionalParameters
    )
    $Target = "BetterCredentials", $VaultName, $Name -join "|"

    $Credential = [BetterCredentials.Store]::Load($Target, "Generic")

    $Type, $Description = $Credential.Description -Split " ", 2

    switch ($Type) {
        "string" {
            # Nested hashtable sub-vaults return strings directly
            if ($VaultName.StartsWith("HT_")) {
                $Credential.GetNetworkCredential().Password
            } else {
                $Credential.Password
            }
        }
        "ByteArray" {
            [Convert]::FromBase64String($Credential.GetNetworkCredential().Password)
        }
        "SecureString" {
            $Credential.Password
        }
        "Hashtable" {
            $Result = @{}
            # We stored Hashtables by recursing...
            $NestedAdditionalParameters = $AdditionalParameters.Clone()
            $keys = $Credential.GetNetworkCredential().Password.Split("|")
            foreach ($key in $keys) {
                $Result[$key] = Get-Secret "$Name|$key" "HT_$VaultName" $NestedAdditionalParameters
            }
            $Result
        }
        "PSCredential" {
            $Credential
        }
        # Credentials that we didn't put in there ...
        default {
            $Credential
        }
    }
}
