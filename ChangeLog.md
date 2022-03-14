### 5.0 Big release (but tiny breaking change)

    1. Added support for Microsoft.PowerShell.SecretManagement (on Windows only). Exposes all credentials in the Windows Credential Manager to SecretManagement.
    2. Added a [BetterCredentials.Credential()] attribute that is compatible with, but better than the built-in one. It supports specifying the Title and Message for the credential prompt, as well as the "Target" and "Description" to be stored in the credential. Of course, since this is BetterCredentials, it also supports automatically saving and loading credentials automatically.
    2. Added a converter to allow casting to different credential types:
        - System.Management.Automation.PSCredential
        - System.Net.NetworkCredential
        - System.Data.SqlClient.SqlCredential

    Breaking changes:
    - By default, Find and Test now search only credentials added by BetterCredentials.
        To get the previous behavior, you need to provide the -AllCredentials switch
    - Removed the -Delete switch from Get-Credential
        It was a bad idea, and we no longer need it, since we added Remove-Credential
        Since this is a breaking change release, might as well remove it

### v 4.5 Add a lot of functionality to the module, allowing enumeration and deletion, etc.
    - Add Test-Credential for explicitly checking whether a credential is already stored
    - Add Set-Credential for explicitly storing or updating stored credentials
    - Add Remove-Credential for clearing stored credentials
    - Add Find-Credential to search stored credentials

### Ancient History

#### v 4.4 Add a Test-Credential

#### v 4.3 Update module metadata and copyrights, etc.

#### v 4.2 Provide -Force switch to force prompting instead of loading

#### v 4.1 Modularize and Release

#### v 4.0 Change -Store to save credentials in the Windows Credential Manager (Vault)

#### v 3.0 Modularize so I can "Requires" it

#### v 2.9 Reformat to my new coding style...

#### v 2.8 Refactor EncodeSecureString (and add unused DecodeSecureString for completeness)

    NOTE these are not at all like the built-in ConvertFrom/ConvertTo-SecureString

#### v 2.7 Fix double prompting issue when using -Inline

    Use full typename for PSCredential to maintain V2 support - Thanks Joe Hayes

#### v 2.6 Put back support for passing in the domain when getting credentials without prompting

#### v 2.5 Added examples for the help

#### v 2.4 Fix a bug in -Store when the UserName isn't passed in as a parameter

#### v 2.3 Add -Store switch and support putting credentials into the file system

#### v 2.1 Fix the comment help and parameter names to agree with each other (whoops)

#### v 2.0 Rewrite for v2 to replace the default Get-Credential

#### v 1.2 Refactor ShellIds key out to a variable, and wrap lines a bit

#### v 1.1 Add -Console switch and set registry values accordingly (ouch)

#### v 1.0 Add Title, Description, Domain, and UserName options to the Get-Credential cmdlet