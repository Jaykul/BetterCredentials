function Set-Secret {
    [CmdletBinding()]
    param(
        [string] $Name,
        [object] $Secret,
        [string] $VaultName,
        [hashtable] $AdditionalParameters
    )
    $Prefix = "$($AdditionalParameters["Prefix"])"

    $CredVaultData = @{
        Type        = [BetterCredentials.CredentialType]::Generic
        Target      = "$Prefix$Name"
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
            [PSCredential]::new("--Hashtable--", (ConvertTo-SecureString ($Secret | ConvertTo-Json -Compress -Depth 99) -AsPlainText -Force))
            $CredVaultData['Description'] = "Hashtable"
        }
        default: {
            [PSCredential]::new("--unknown--", (ConvertTo-SecureString ($Secret | ConvertTo-Json -Compress -Depth 99) -AsPlainText -Force))
            $CredVaultData['Description'] = "Unknown"
        }
    }

    $Credential | Add-Member -NotePropertyMembers $CredVaultData
    [BetterCredentials.Store]::Save($Credential)
}
