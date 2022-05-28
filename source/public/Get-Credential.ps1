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
            For a brief history of this command, see the ChangeLog.

    #>
    [Alias('gcred')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password", Justification = "Let the user beware, this is a useful option")]
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

        # The Target allows you to specify what the credentials are for, so you can store multiple credentials with the same username but different passwords.
        # For example, you could set the target to the URL of a website or the name of a server the credential is for.
        #
        # If not specified, by default BetterCredentials builds a target string from the credential's user name: MicrosoftPowerShell:user=$User
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

        #  Store the credential in SecretManagement (overwriting existing credentials for the same target)
        [Parameter(ParameterSetName = "Prompted", Mandatory = $false)]
        [Parameter(ParameterSetName = "Promptless", Mandatory = $false)]
        [switch]$Store,

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
            if (!$PSBoundParameters.ContainsKey("Target")) {
                $Target = "$(if ($Domain) {"${Domain}\" })$($Credential.UserName)"
            }
        } elseif (!$Force -and $UserName -ne $null -or $Target) {
            $UserName = "$UserName"
            if (!$PSBoundParameters.ContainsKey("Target")) {
                $Target = "$(if ($Domain) {"${Domain}\" })${UserName}"
            }
            # For cross-platform purposes, we now use SecretManagement to store credentials when it's available
            # If SecretManagement is not available, we support the old method via our Extension module
            $Credential = & $script:ImplementationModule\Get-Secret $Target @BetterCredentialsSecretManagementParameters
        }

        Write-Verbose "UserName: $(if($Credential){$Credential.UserName}else{$UserName})"
        if ($Password) {
            if ($Password -isnot [System.Security.SecureString]) {
                $Password = [BetterCredentials.SecureStringHelper]::CreateSecureString($Password)
            }
            Write-Verbose "Creating credential from inline Password"

            if ($Domain) {
                $Cred = [System.Management.Automation.PSCredential]::new("${Domain}\${UserName}", ${Password})
            } else {
                $Cred = [System.Management.Automation.PSCredential]::new(${UserName}, ${Password})
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
                $Credential = [System.Management.Automation.PSCredential]::new($UserName, (Read-Host "Password for user $UserName" -AsSecureString))
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
            $Cred = [System.Management.Automation.PSCredential]::new(${UserName}, $Credential.Password)
            if ($Credential) {
                $Credential | Get-Member -type NoteProperty | ForEach-Object {
                    Add-Member -InputObject $Cred -MemberType NoteProperty -Name $_.Name -Value $Credential.($_.Name) -Force
                }
            }
            $Credential = $Cred
        }

        if ($Store) {
            $Metadata = @{}
            # If the user passed the value, or if it's not set
            if ($PSBoundParameters.ContainsKey("Type") -or !$Credential.Type) {
                $Credential | Add-Member NoteProperty Type $Type -Force
                $Metadata["Type"] = $Type
            }

            if ($PSBoundParameters.ContainsKey("Persistence") -or !$Credential.Persistence) {
                $Credential | Add-Member NoteProperty Persistence $Persistence
                $Metadata["Persistence"] = $Persistence
            }

            if ($PSBoundParameters.ContainsKey("Description")) {
                $Credential | Add-Member NoteProperty Description $Description -Force
                $Metadata["Description"] = $Description
            }
            & $script:ImplementationModule\Set-Secret -Name $Target -Secret $Credential @BetterCredentialsSecretManagementParameters

            if ($Metadata) {
                & $script:ImplementationModule\Set-SecretInfo -Name $Target -Metadata $Metadata @BetterCredentialsSecretManagementParameters
            }
        }

        return $Credential
    }
}