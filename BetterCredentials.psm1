$ScriptRoot = Get-Variable PSScriptRoot -ErrorAction SilentlyContinue | ForEach-Object { $_.Value }
if(!$ScriptRoot) {
  $ScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
}

Add-Type -Path $ScriptRoot\NativeMethods.cs


function Get-Credential { 
   # .Synopsis
   #    Gets a credential object based on a user name and password.
   # .Description
   #    The Get-Credential function creates a credential object for a specified username and password, with an optional domain. You can use the credential object in security operations.
   # 
   #    This function is an improvement over the default Get-Credential cmdlet in several ways:
   #    Obviously it accepts more parameters to customize the security prompt (including forcing the call through the console) 
   #    It also supports storing and retrieving credentials in your Windows Credential Manager, but otherwise functions identically to the built-in command
   #
   #    Whenever you pass a UserName as a parameter to Get-Credential, it will attempt to read the credential from your Vault.
   # .Example
   #    Get-Credential UserName -store
   # 
   #    If you haven't stored the password for "UserName", you'll be prompted with the regular PowerShell credential prompt, otherwise it will read the stored password.
   #    In either case, it will store (update) the credentials in the Vault 
   # .Example
   #    $Cred = Get-Credential -user key -pass secret | Get-Credential -Store
   #    Get-Credential -user key | % { $_.GetNetworkCredential() } | fl *
   # 
   #    This example demonstrates the ability to pass passwords as a parameter.
   #    It also shows how to pass credentials in via the pipeline, and then to store and retrieve them
   #    NOTE: These passwords are stored in the Windows Credential Vault.  You can review them in the Windows "Credential Manager" (they will show up prefixed with "WindowsPowerShell")
   # .Example
   #    Get-Credential -inline
   #  
   #    Will prompt for credentials inline in the host instead of in a popup dialog
   #  .Notes
   #    History:
   #     v 4.0 Change -Store to save credentials in the Windows Credential Manager (Vault)
   #     v 3.0 Modularize so I can "Requires" it
   #     v 2.9 Reformat to my new coding style...
   #     v 2.8 Refactor Encode-SecureString (and add unused Decode-SecureString for completeness)
   #           NOTE these are not at all like the built-in ConvertFrom/ConvertTo-SecureString
   #     v 2.7 Fix double prompting issue when using -Inline 
   #           Use full typename for PSCredential to maintain V2 support - Thanks Joe Hayes
   #     v 2.6 Put back support for passing in the domain when getting credentials without prompting
   #     v 2.5 Added examples for the help
   #     v 2.4 Fix a bug in -Store when the UserName isn't passed in as a parameter
   #     v 2.3 Add -Store switch and support putting credentials into the file system
   #     v 2.1 Fix the comment help and parameter names to agree with each other (whoops)
   #     v 2.0 Rewrite for v2 to replace the default Get-Credential
   #     v 1.2 Refactor ShellIds key out to a variable, and wrap lines a bit
   #     v 1.1 Add -Console switch and set registry values accordingly (ouch)
   #     v 1.0 Add Title, Description, Domain, and UserName options to the Get-Credential cmdlet
   [OutputType("System.Management.Automation.PSCredential")]
   [CmdletBinding(DefaultParameterSetName="Prompted")]
   param(
      #   A default user name for the credential prompt, or a pre-existing credential (would skip all prompting)
      [Parameter(ParameterSetName="Prompted",Position=1,Mandatory=$false,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
      [Parameter(ParameterSetName="Delete",Position=1,Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
      [Parameter(ParameterSetName="Promptless",Position=1,Mandatory=$true)]
      [Alias("Credential")]
      [PSObject]$UserName=$null,

      #  Allows you to override the default window title of the credential dialog/prompt
      #
      #  You should use this to allow users to differentiate one credential prompt from another.  In particular, if you're prompting for, say, Twitter credentials, you should put "Twitter" in the title somewhere. If you're prompting for domain credentials. Being specific not only helps users differentiate and know what credentials to provide, but also allows tools like KeePass to automatically determine it.
      [Parameter(ParameterSetName="Prompted",Position=2,Mandatory=$false)]
      [string]$Title=$null,

      #  Allows you to override the text displayed inside the credential dialog/prompt.
      #  Note: this is stored with the credentials as the "Description"
      #  
      #  You should use this to describe what the credentials are for.
      [Parameter(ParameterSetName="Prompted",Position=3,Mandatory=$false)]
      [string]$Description=$null,

      #  Specifies the default domain to use if the user doesn't provide one (by default, this is null)
      [Parameter(ParameterSetName="Prompted",Mandatory=$false)]
      [Parameter(ParameterSetName="Promptless",Mandatory=$false)]
      [string]$Domain=$null,

      #  The Get-Credential cmdlet forces you to always return DOMAIN credentials (so even if the user provides just a plain user name, it prepends "\" to the user name). This switch allows you to override that behavior and allow generic credentials without any domain name or the leading "\".
      [Parameter(ParameterSetName="Prompted",Mandatory=$false)]
      [Parameter(ParameterSetName="Promptless",Mandatory=$false)]
      [switch]$GenericCredentials,

      #  Forces the credential prompt to occur inline in the console/host using Read-Host -AsSecureString (not implemented properly in PowerShell ISE)
      [Parameter(ParameterSetName="Prompted",Mandatory=$false)]
      [switch]$Inline,

      #  Store the credential in the file system (overwriting existing credentials)
      #  NOTE: These passwords are STORED ON DISK encrypted using Windows DPAPI
      #        They are encrypted, but anyone with ACCESS TO YOUR LOGIN ACCOUNT can decrypt them
      [Parameter(ParameterSetName="Prompted",Mandatory=$false)]
      [Parameter(ParameterSetName="Promptless",Mandatory=$false)]
      [switch]$Store,

      #  Remove stored credentials from the file system
      [Parameter(ParameterSetName="Delete",Mandatory=$true)]
      [switch]$Delete,

      #  The password
      [Parameter(ParameterSetName="Promptless",Mandatory=$true)]
      $Password
   )
   process {
      Write-Verbose ($PSBoundParameters | Out-String)
      [Management.Automation.PSCredential]$Credential = $null
      if( $UserName -is [Management.Automation.PSCredential]) {
         $Credential = $UserName
      } elseif($UserName -ne $null) {
         $UserName = $UserName.ToString()
         if($Domain) {
            if($Delete) {
               [CredentialManagement.Store]::Delete("${Domain}\${UserName}")
            } else {
               $Credential = [CredentialManagement.Store]::Load("${Domain}\${UserName}")
            }
         } else {
            if($Delete) {
               [CredentialManagement.Store]::Delete($UserName)
            } else {            
               $Credential = [CredentialManagement.Store]::Load($UserName)
            }
         }
      }

      Write-Verbose "UserName: $(if($Credential){$Credential.UserName}else{$UserName})"
      if($Password) {
         if($Password -isnot [Security.SecureString]) {
            $Password = Encode-SecureString $Password
         }
         Write-Verbose "Creating credential from inline Password"

         if($Domain) {
            $Cred = New-Object Management.Automation.PSCredential ${Domain}\${UserName}, ${Password}
         } else {
            $Cred = New-Object Management.Automation.PSCredential ${UserName}, ${Password}
         }
         if($Credential) {
            $Credential | Get-Member -type NoteProperty | % {
               Add-Member -InputObject $Cred -MemberType NoteProperty -Name $_.Name -Value $Credential.($_.Name) 
            }
         }
         $Credential = $Cred
      }
      
      Write-Verbose "Password: $(if($Credential){$Credential.Password}else{$Password})"
      if(!$Credential) {
         Write-Verbose "Prompting for credential"
         if($Inline) {
            if($Title)      { Write-Host $Title }
            if($Description){ Write-Host $Description }
            if($Domain)     { 
               if($UserName -and $UserName -notmatch "[@\\]") { 
                  $UserName = "${Domain}\${UserName}"
               }
            }
            if(!$UserName) {
               $UserName = Read-Host "User"
               if(($Domain -OR !$GenericCredentials) -and $UserName -notmatch "[@\\]") {
                  $UserName = "${Domain}\${UserName}"
               }
            }
            Write-Verbose "Generating Credential with Read-Host -AsSecureString"
            $Credential = New-Object Management.Automation.PSCredential $UserName,$(Read-Host "Password for user $UserName" -AsSecureString)
         } else {
            if($GenericCredentials) { $Type = "Generic" } else { $Type = "Domain" }
         
            ## Now call the Host.UI method ... if they don't have one, we'll die, yay.
            ## BugBug? PowerShell.exe (v2) disregards the last parameter
            Write-Debug "Generating Credential with Host.UI.PromptForCredential($Title, $Description, $UserName, $Domain, $Type, $Options)"
            $Options = if($UserName) { "ReadOnlyUserName" } else { "Default" }
            $Credential = $Host.UI.PromptForCredential($Title, $Description, $UserName, $Domain, $Type, $Options)
         }
      }
      


      if($Store) {
         if($Description) {
            Add-Member -InputObject $Credential -MemberType NoteProperty -Name Description -Value $Description
         }
         $result = [CredentialManagement.Store]::Save($Credential)
         if($result -ne "NO_ERROR") {
            Write-Error $result
         }
      }
      return $Credential
   }
}

function Decode-SecureString {
   #.Synopsis
   #  Decodes a SecureString to a String
   [CmdletBinding()]
   [OutputType("System.String")]
   param(
      # The SecureString to decode
      [Parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
      [Alias("Password")]
      [SecureString]$secure
   )
   end {
      if($secure -eq $null) { return "" }
      $BSTR = [Runtime.InteropServices.marshal]::SecureStringToBSTR($secure)
      Write-Output [Runtime.InteropServices.marshal]::PtrToStringAuto($BSTR)
      [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
   }
}

function Encode-SecureString {
   #.Synopsis
   #  Encodes a string as a SecureString (for this computer/user)
   [CmdletBinding()]
   [OutputType("System.Security.SecureString")]
   param(
      # The string to encode into a secure string
      [Parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
      [String]$String
   )
   end {
      [char[]]$Chars = $String.ToString().ToCharArray()
      $SecureString = New-Object Security.SecureString
      foreach($c in $chars) { $SecureString.AppendChar($c) }
      $SecureString.MakeReadOnly();
      Write-Output $SecureString
   }
}
New-Alias gcred Get-Credential
Export-ModuleMember -Function Get-Credential -Alias gcred