function Get-Credential {
    <#
       .Synopsis
          Gets a credential object based on a user name and password.
       .Description
          The Get-Credential function creates a credential object for a specified username and password, with an optional domain. You can use the credential object in security operations.

          This function is an improvement over the default Get-Credential cmdlet in several ways:
          Obviously it accepts more parameters to customize the security prompt (including forcing the call through the console)
          It also supports storing and retrieving credentials in your Windows Credential Manager, but otherwise functions identically to the built-in command

          Whenever you pass a UserName as a parameter to Get-Credential, it will attempt to read the credential from your Vault.
       .Example
          Get-Credential UserName -store

          If you haven't stored the password for "UserName", you'll be prompted with the regular PowerShell credential prompt, otherwise it will read the stored password.
          In either case, it will store (update) the credentials in the Vault
       .Example
          $Cred = Get-Credential -user key -pass secret | Get-Credential -Store
          Get-Credential -user key | % { $_.GetNetworkCredential() } | fl *

          This example demonstrates the ability to pass passwords as a parameter.
          It also shows how to pass credentials in via the pipeline, and then to store and retrieve them
          NOTE: These passwords are stored in the Windows Credential Vault.  You can review them in the Windows "Credential Manager" (they will show up prefixed with "WindowsPowerShell")
       .Example
          Get-Credential -inline

          Will prompt for credentials inline in the host instead of in a popup dialog
        .Notes
          History:
           v 4.5 Add Find-Credential, Set-Credential, Remove-Credential
           v 4.4 Add a Test-Credential
           v 4.3 Update module metadata and copyrights, etc.
           v 4.2 Provide -Force switch to force prompting instead of loading
           v 4.1 Modularize and Release
           v 4.0 Change -Store to save credentials in the Windows Credential Manager (Vault)
           v 3.0 Modularize so I can "Requires" it
           v 2.9 Reformat to my new coding style...
           v 2.8 Refactor EncodeSecureString (and add unused DecodeSecureString for completeness)
                 NOTE these are not at all like the built-in ConvertFrom/ConvertTo-SecureString
           v 2.7 Fix double prompting issue when using -Inline
                 Use full typename for PSCredential to maintain V2 support - Thanks Joe Hayes
           v 2.6 Put back support for passing in the domain when getting credentials without prompting
           v 2.5 Added examples for the help
           v 2.4 Fix a bug in -Store when the UserName isn't passed in as a parameter
           v 2.3 Add -Store switch and support putting credentials into the file system
           v 2.1 Fix the comment help and parameter names to agree with each other (whoops)
           v 2.0 Rewrite for v2 to replace the default Get-Credential
           v 1.2 Refactor ShellIds key out to a variable, and wrap lines a bit
           v 1.1 Add -Console switch and set registry values accordingly (ouch)
           v 1.0 Add Title, Description, Domain, and UserName options to the Get-Credential cmdlet
    #>
    [Alias('gcred')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password", Justification = "Let other people worry about that, this is a useful option")]
    [OutputType("System.Management.Automation.PSCredential")]
    [CmdletBinding(DefaultParameterSetName = "Prompted")]
    param(
        #   A default user name for the credential prompt, or a pre-existing credential (would skip all prompting)
        [Parameter(ParameterSetName = "Prompted", Position = 1, Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Parameter(ParameterSetName = "Delete", Position = 1, Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Parameter(ParameterSetName = "Promptless", Position = 1, Mandatory = $true)]
        # [Parameter(ParameterSetName = "Stored", Position = 1, Mandatory = $true)]
        [Alias("Credential")]
        [PSObject]$UserName = $null,

        #  Allows you to override the default window title of the credential dialog/prompt
        #
        #  You should use this to allow users to differentiate one credential prompt from another.  In particular, if you're prompting for, say, Twitter credentials, you should put "Twitter" in the title somewhere. If you're prompting for domain credentials. Being specific not only helps users differentiate and know what credentials to provide, but also allows tools like KeePass to automatically determine it.
        [Parameter(ParameterSetName = "Prompted", Position = 2, Mandatory = $false)]
        [string]$Title = $null,

        # The Target allows you to set a consistent name for credentials so you can store multiple credentials with the same username and be able to recall them.
        # For example, you could set the target to the URL of a website or the name of a server the credential is for.
        #
        # By default BetterCredentials builds a target string from the credential's user name: MicrosoftPowerShell:user=$User
        [Parameter()]
        [string]$Target,

        #  Allows you to override the text displayed inside the credential dialog/prompt.
        #  Note: this is stored with the credentials as the "Description"
        #
        #  You should use this to describe what the credentials are for.
        [Parameter(ParameterSetName = "Prompted", Position = 3, Mandatory = $false)]
        [Alias("Message")]
        [string]$Description = $null,

        #  Specifies the default domain to use if the user doesn't provide one (by default, this is null)
        [Parameter(ParameterSetName = "Prompted", Mandatory = $false)]
        [Parameter(ParameterSetName = "Promptless", Mandatory = $false)]
        [string]$Domain = $null,

        #  The Get-Credential cmdlet forces you to always return DOMAIN credentials (so even if the user provides just a plain user name, it prepends "\" to the user name). This switch allows you to override that behavior and allow generic credentials without any domain name or the leading "\".
        [Parameter(ParameterSetName = "Prompted", Mandatory = $false)]
        [Parameter(ParameterSetName = "Promptless", Mandatory = $false)]
        [switch]$GenericCredentials,

        #  Forces the credential prompt to occur inline in the console/host using Read-Host -AsSecureString (not implemented properly in PowerShell ISE)
        [Parameter(ParameterSetName = "Prompted", Mandatory = $false)]
        [switch]$Inline,

        #  Store the credential in the file system (overwriting existing credentials)
        #  NOTE: These passwords are STORED ON DISK encrypted using Windows DPAPI
        #        They are encrypted, but anyone with ACCESS TO YOUR LOGIN ACCOUNT can decrypt them
        [Parameter(ParameterSetName = "Prompted", Mandatory = $false)]
        [Parameter(ParameterSetName = "Promptless", Mandatory = $false)]
        [switch]$Store,

        #  Remove stored credentials from the file system
        [Parameter(ParameterSetName = "Delete", Mandatory = $true)]
        [switch]$Delete,

        # Ignore stored credentials and re-prompt
        # Note: when combined with -Store this overwrites stored credentials
        [Alias("New")]
        [switch]$Force,

        #  The password
        [Parameter(ParameterSetName = "Promptless", Mandatory = $true)]
        $Password
    )
    process {
        Write-Verbose ($PSBoundParameters | Out-String)
        [Management.Automation.PSCredential]$Credential = $null
        if ($UserName -is [System.Management.Automation.PSCredential]) {
            $Credential = $UserName
        } elseif (!$Force -and $UserName -ne $null -or $Target) {
            $UserName = "$UserName"
            if (!$PSBoundParameters.ContainsKey("Target")) {
                $Target = "$(if ($Domain) {"${Domain}\" })${UserName}"
            }
            if ($Delete) {
                [BetterCredentials.Store]::Delete($Target, "Generic", !$PSBoundParameters.ContainsKey("Target"))
            } else {
                try {
                    $Credential = [BetterCredentials.Store]::Load($Target, "Generic", !$PSBoundParameters.ContainsKey("Target"))
                } catch {}

                # support loading any type of credentials if they specify a Target
                if (!$Credential -and $PSBoundParameters.ContainsKey("Target")) {
                    foreach ($Type in (([BetterCredentials.CredentialType]::None)..([BetterCredentials.CredentialType]::Maximum))) {
                        try {
                            $Credential = [BetterCredentials.Store]::Load($Target, $Type, !$PSBoundParameters.ContainsKey("Target"))
                        } catch {}
                        if ($Credential) { break }
                    }
                }
            }
        }

        Write-Verbose "UserName: $(if($Credential){$Credential.UserName}else{$UserName})"
        if ($Password) {
            if ($Password -isnot [System.Security.SecureString]) {
                $Password = EncodeSecureString $Password
            }
            Write-Verbose "Creating credential from inline Password"

            if ($Domain) {
                $Cred = New-Object System.Management.Automation.PSCredential ${Domain}\${UserName}, ${Password}
            } else {
                $Cred = New-Object System.Management.Automation.PSCredential ${UserName}, ${Password}
            }
            if ($Credential) {
                $Credential | Get-Member -type NoteProperty | ForEach-Object {
                    Add-Member -InputObject $Cred -MemberType NoteProperty -Name $_.Name -Value $Credential.($_.Name) -Force
                }
            }
            $Credential = $Cred
        }

        Write-Verbose "Password: $(if($Credential){$Credential.Password}else{$Password})"
        if (!$Credential) {
            Write-Verbose "Prompting for credential"
            if ($Inline) {
                if ($Title) {
                    Write-Host $Title
                }
                if ($Description) {
                    Write-Host $Description
                }
                if ($Domain) {
                    if ($UserName -and $UserName -notmatch "[@\\]") {
                        $UserName = "${Domain}\${UserName}"
                    }
                }
                if (!$UserName) {
                    $UserName = Read-Host "User"
                    if (($Domain -OR !$GenericCredentials) -and $UserName -notmatch "[@\\]") {
                        $UserName = "${Domain}\${UserName}"
                    }
                }
                Write-Verbose "Generating Credential with Read-Host -AsSecureString"
                $Credential = New-Object System.Management.Automation.PSCredential $UserName, $(Read-Host "Password for user $UserName" -AsSecureString)
            } else {
                if ($GenericCredentials) {
                    $Type = "Generic"
                } else {
                    $Type = "Domain"
                }

                ## Now call the Host.UI method ... if they don't have one, we'll die, yay.
                ## BugBug? PowerShell.exe (v2) disregards the last parameter
                Write-Debug "Generating Credential with Host.UI.PromptForCredential($Title, $Description, $UserName, $Domain, $Type, $Options)"
                $Options = if ($UserName) {
                    "ReadOnlyUserName"
                } else {
                    "Default"
                }
                $Credential = $Host.UI.PromptForCredential($Title, $Description, $UserName, $Domain, $Type, $Options)
            }
        }

        # Make sure it's Generic
        if ($GenericCredentials -and $Credential.UserName.Contains("\")) {
            ${UserName} = @($Credential.UserName -Split "\\")[-1]
            $Cred = New-Object System.Management.Automation.PSCredential ${UserName}, $Credential.Password
            if ($Credential) {
                $Credential | Get-Member -type NoteProperty | ForEach-Object {
                    Add-Member -InputObject $Cred -MemberType NoteProperty -Name $_.Name -Value $Credential.($_.Name) -Force
                }
            }
            $Credential = $Cred
        }

        if ($Store) {
            if ($Description) {
                Add-Member -InputObject $Credential -MemberType NoteProperty -Name Description -Value $Description
            }
            if ($PSBoundParameters.ContainsKey("Target")) {
                Add-Member -InputObject $Credential -MemberType NoteProperty -Name Target -Value $Target -Force
            }
            [BetterCredentials.Store]::Save($Credential)
        }

        return $Credential
    }
}