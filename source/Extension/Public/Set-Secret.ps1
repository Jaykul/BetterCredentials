function Set-Secret {
    [CmdletBinding()]
    param(
        [string] $Name,
        [object] $Secret,
        [string] $VaultName,
        [hashtable] $AdditionalParameters
    )
    $Target = FixTarget @PSBoundParameters

    $CredVaultData = @{
        Type        = if ($Secret.Type -as [BetterCredentials.CredentialType]) { [BetterCredentials.CredentialType]$Secret.Type } else { [BetterCredentials.CredentialType]::Generic }
        Target      = if ($Secret.ForceTarget) { $Secret.ForceTarget } else { $Target }
        TargetAlias = if ($Secret.ForceTarget) { $Target } else { $Name }
        Persistence = [BetterCredentials.PersistenceType]::LocalComputer
    }

    if ($AdditionalParameters -and $AdditionalParameters.ContainsKey("Persistence")) {
        $CredVaultData["Persistence"] = $AdditionalParameters["Persistence"]
    }

    $Credential = switch ($Secret.GetType().Name) {
        "string" {
            [PSCredential]::new("--String--", ([BetterCredentials.SecureStringHelper]::CreateSecureString($Secret)))
            $CredVaultData['Description'] = "String"
        }
        "byte[]" {
            [PSCredential]::new("--ByteArray--", ([BetterCredentials.SecureStringHelper]::CreateSecureString(([Convert]::ToBase64String($Secret)))))
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
                [PSCredential]::new("--Hashtable--", ([BetterCredentials.SecureStringHelper]::CreateSecureString(($Secret.Keys -join "|"))))
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
