function Get-Secret {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $Name,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $VaultName,

        [hashtable] $AdditionalParameters
    )
    process {
        $Target = FixTarget @PSBoundParameters

        $Credential = [BetterCredentials.Store]::Load($Target, "Generic")

        $Type, $Description = $Credential.Description -Split " ", 2

        switch ($Type) {
            "string" {
                # Nested hashtable sub-vaults return strings directly
                if ($VaultName.StartsWith("HT_")) {
                    [BetterCredentials.SecureStringHelper]::CreateString($Credential.Password)
                } else {
                    $Credential.Password
                }
            }
            "ByteArray" {
                [Convert]::FromBase64String([BetterCredentials.SecureStringHelper]::CreateString($Credential.Password))
            }
            "SecureString" {
                $Credential.Password
            }
            "Hashtable" {
                $Result = @{}
                # We stored Hashtables by recursing...
                $NestedAdditionalParameters = $AdditionalParameters.Clone()
                $keys = [BetterCredentials.SecureStringHelper]::CreateString($Credential.Password).Split("|")
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
}