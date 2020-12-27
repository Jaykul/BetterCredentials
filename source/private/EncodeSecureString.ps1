function EncodeSecureString {
    #.Synopsis
    #  Encodes a string as a SecureString (for this computer/user)
    [CmdletBinding()]
    [OutputType("System.Security.SecureString")]
    param(
        # The string to encode into a secure string
        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [String]$String
    )
    end {
        [char[]]$Chars = $String.ToString().ToCharArray()
        $SecureString = New-Object System.Security.SecureString
        foreach ($c in $chars) {
            $SecureString.AppendChar($c)
        }
        $SecureString.MakeReadOnly();
        Write-Output $SecureString
    }
}