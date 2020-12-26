function DecodeSecureString {
    #.Synopsis
    #  Decodes a SecureString to a String
    [CmdletBinding()]
    [OutputType("System.String")]
    param(
        # The SecureString to decode
        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias("Password")]
        [SecureString]$secure
    )
    end {
        if ($secure -eq $null) {
            return ""
        }
        $BSTR = [System.Runtime.InteropServices.marshal]::SecureStringToBSTR($secure)
        Write-Output [System.Runtime.InteropServices.marshal]::PtrToStringAuto($BSTR)
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
    }
}