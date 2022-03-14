Add-Type -Path $PSScriptRoot\BetterCredentials.cs

<#
    The Credential Manager Vault, exposed to SecretManagement and automation.

    TO BE CLEAR:
    - This module does not change the level of security of your Credential Manager Vault, which is encrypted by Windows to your user account (and by default, to your local machine).
    - It is similar to the built-in `cmdkey` utility, but object-oriented and integrated with PowerShell SecretManagement.
    - Credentials in your Windows Credential Manager are encrypted, but anyone with access to your Windows user account can read them. There is no _additional_ access prompt or password required.
    - Credentials can be backed up via the Credential Manager, but are not backed up by Windows or OneDrive.


    In order to support multiple named "vaults" this extension module supports an AdditionalParameter "Prefix" which we prefix on credential names for filtering and retrieving.

    In order to cram support for non-credential secrets in, we store the Type as the first word in the description.
#>
$DefaultPrefix = "MicrosoftPowerShell:user="

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

function Get-SecretInfo {
    <#
        This is the "list" function.
        SecretManagement's Get-SecretInfo calls this
        It passes -Filter * by default

    #>
    [CmdletBinding()]
    param (
        [string]$Filter,
        [string]$VaultName,
        [hashtable]$AdditionalParameters
    )
    $Prefix = "$($AdditionalParameters["Prefix"])"
    $Filter = "$Prefix$Filter"

    [BetterCredentials.Store]::Find($Filter).ForEach({
        $Metadata = @{
            Description   = $_.Description
            Type          = $_.Type
            Persistance   = $_.Persistance
            LastWriteTime = $_.LastWriteTime
            Target        = $_.Target
            TargetAlias   = $_.TargetAlias
        }

        # WE shove the Type and Metadata into the Type, space separated
        # But credentials entered by others are unlikely to match this format

        $Type, $Description = $_.Description -Split " ", 2
        if (!($Type -as [Microsoft.PowerShell.SecretManagement.SecretType])) {
            $Type = "Unknown"
        } elseif ($Description) {
            # On PowerShell 5.x there's no -AsHashtable, so we'll just use objects..
            if ($MetadataObject = $Description | ConvertFrom-Json -ErrorAction SilentlyContinue) {
                $MetadataObject.psobject.properties.ForEach({
                    $Metadata[$_.name] = $_.value
                })
            }
        }

        # If there's a prefix, strip it off the Name
        $Name = if ($Prefix) {
            $_.Target -replace "^$([regex]::Escape($Prefix))"
        } else {
            $_.Target
        }
        [Microsoft.PowerShell.SecretManagement.SecretInformation]::new(
            $Name,
            $Type,
            $VaultName,
            $Metadata
        )
    })
}

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

function Set-SecretInfo {
    [CmdletBinding()]
    param (
        [string] $Name,
        [hashtable] $Metadata,
        [string] $VaultName,
        [hashtable] $AdditionalParameters
    )
    Write-Error "Not implemented"

    $Name = $AdditionalParameters["Prefix"] + $Name

    $Credential = [BetterCredentials.Store]::Load($Name, "Generic")

    $Type, $Description = $_.Description -Split " ", 2
    if (!($Type -as [Microsoft.PowerShell.SecretManagement.SecretType])) {
        $Type = "Unknown"
    }
    $Credential.Description = $Type + " " + $Metadata | ConvertTo-Json -Compress -Depth 99
    [BetterCredentials.Store]::Save($Credential)
}

function Remove-Secret {
    [CmdletBinding()]
    param (
        [string] $Name,
        [string] $VaultName,
        [hashtable] $AdditionalParameters
    )

    [BetterCredentials.Store]::Delete($Name, "Generic")
}

function Test-SecretVault {
    [CmdletBinding()]
    param (
        [string] $VaultName,
        [hashtable] $AdditionalParameters
    )
    # I don't know if this is right, but I think it proves CredMan works
    [BetterCredentials.Store]::Find("*").Count -gt 0
}
