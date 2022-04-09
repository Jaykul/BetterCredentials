function Set-Secret {
    [CmdletBinding()]
    param(
        [string] $Name,
        [object] $Secret,
        [string] $VaultName,
        [hashtable] $AdditionalParameters
    )

    $CredVaultData = @{
        Type        = [BetterCredentials.CredentialType]::Generic
        Target      = "$($AdditionalParameters.Prefix)$Name"
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
            $Serialized = $Secret | ConvertTo-Json -Compress -Depth 99
            $Encrypted = ConvertTo-SecureString $Serialized -AsPlainText -Force
            if ($Encrypted.Length -gt 1280) {
                throw ([InvalidOperationException]"Secret cannot be more than 1280 characters (was " + $Encrypted.Length + ")")
            }
            # Make sure round-trip will actually work
            if (Get-Command ConvertFrom-Json -ParameterName AsHashtable -ErrorAction Ignore) {
                $Deserialized = $Serialized | ConvertFrom-Json -AsHashtable
            } else {
                Write-Warning "Hashtable secrets are not supported on this version of PowerShell"
                $Deserialized = $Serialized | ConvertFrom-Json
            }
            $RoundTrip = $Deserialized | ConvertTo-Json -Compress -Depth 99
            # BUG: This isn't valid, because hashtable order isn't necessarily preserved
            if ($RoundTrip -ne $Serialized) {
                throw ([InvalidOperationException]"Hashtables with complex objects are not supported.")
            }

            [PSCredential]::new("--Hashtable--", (ConvertTo-SecureString $Serialized -AsPlainText -Force))
            $CredVaultData['Description'] = "Hashtable"
        }
        default {
            [PSCredential]::new("--unknown--", (ConvertTo-SecureString ($Secret | ConvertTo-Json -Compress -Depth 99) -AsPlainText -Force))
            $CredVaultData['Description'] = "Unknown"
        }
    }

    $Credential | Add-Member -NotePropertyMembers $CredVaultData -Force
    [BetterCredentials.Store]::Save($Credential)
}
