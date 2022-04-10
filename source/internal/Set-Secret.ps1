function Set-Secret {
    [CmdletBinding()]
    param(
        [string] $Name,
        [object] $Secret,
        [string] $VaultName,
        [hashtable] $AdditionalParameters
    )
    $Target = "BetterCredentials", $VaultName, $Name -join "|"

    $CredVaultData = @{
        Type        = [BetterCredentials.CredentialType]::Generic
        Target      = $Target
        TargetAlias = $Name
        Persistance = [BetterCredentials.PersistanceType]::LocalComputer
    }

    if ($AdditionalParameters -and $AdditionalParameters.ContainsKey("Persistance")) {
        $CredVaultData["Persistance"] = $AdditionalParameters["Persistance"]
    }

    $Credential = switch ($Secret.GetType().Name) {
        "string" {
            [PSCredential]::new("--String--", (ConvertTo-SecureString $Secret -AsPlainText -Force))
            $CredVaultData['Description'] = "String"
        }
        "byte[]" {
            [PSCredential]::new("--ByteArray--", (ConvertTo-SecureString ([Convert]::ToBase64String($Secret)) -AsPlainText -Force))
            $CredVaultData['Description'] = "ByteArray"
        }
        "SecureString" {
            [PSCredential]::new("--SecureString--", [SecureString]$Secret)
            $CredVaultData['Description'] = "SecureString"
        }
        "PSCredential" {
            $Secret
            $CredVaultData['Description'] = "PSCredential"
        }
        "hashtable" {
            # Assume Hashtables are really Dictionary<String, object> and store them by recursing...
            $NestedAdditionalParameters = $AdditionalParameters.Clone()
            try {
                foreach ($key in $Secret.Keys) {
                    $Credential = Set-Secret "$Name|$key" $Secret[$key] "HT_$VaultName" $NestedAdditionalParameters
                }
                # And then store a list of keys for the hashtable
                [PSCredential]::new("--Hashtable--", (ConvertTo-SecureString ($Secret.Keys -join "|") -AsPlainText -Force))
            } catch {
                # if we fail to store any of the values, we should clean up by removing the whole thing
                Remove-Secret $Name $Secret $VaultName $AdditionalParameters
                throw $_
            }

            $CredVaultData['Description'] = "Hashtable"
        }
        default {
            throw new InvalidOperationException("Invalid type. Types supported: byte[], string, SecureString, PSCredential, hashtable");
        }
    }

    $Credential | Add-Member -NotePropertyMembers $CredVaultData -Force
    [BetterCredentials.Store]::Save($Credential)
}
