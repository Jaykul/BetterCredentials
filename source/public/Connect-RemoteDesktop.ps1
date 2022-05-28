function Connect-RemoteDesktop {
    <#
        .SYNOPSIS
            Connect an RDP session with PSCredentials

        .DESCRIPTION
            Calls BetterCredentials\Set-Credential to store the credential
            in a way that RemoteDesktop will recognize

        .NOTES
            Inspired by Connect-Mstsc from Jaap Brasser http://www.jaapbrasser.com

        .EXAMPLE
            Connect-RemoteDesktop -ComputerName server01

            Creates a remote desktop session to server01

        .EXAMPLE
            $Cred = BetterCredentials\Get-Credential Jaykul@HuddledMasses.org -Store
            New-RemoteDesktop server01, server02 $Cred

            Creates an RDP session to each of server01 and server02, using the specified credentials

        .EXAMPLE
            Get-ADComputer -Filter { Name -like *SQL* } | New-RemoteDesktop -Credential Jayku@HuddledMasses.org -Width 1024

            Creates an RDP session to each server with a name that has "SQL" in it, using the stored credentials for Jaykul

        .EXAMPLE
            $Cred = BetterCredentials\Find-Credential -Target ContosoAzureRDP
            C:\PS> Get-AzureVM | Get-AzureEndPoint -Name 'Remote Desktop' | New-RemoteDesktop -ComputerName {$_.Vip,$_.Port -join ':'} -Credential $Cred

            First retrieves credentials for ContosoAzureRDP.  You might have stored these previously by running a command like:

            C:\PS> BetterCredentials\Set-Credential -Target ContosoAzureRDP -Credential contoso\joel

            Then, starts an  RDP session for  each Azure Virtual Machine with those credentials
    #>
    [cmdletbinding(SupportsShouldProcess, DefaultParametersetName = 'UserPassword')]
    param (
        # This can be a single computername or an array of computers to which RDP session will be opened
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [Alias('CN','IPAddress')]
        [string[]]$ComputerName,

        # The credential for the remote system
        [Parameter(ValueFromPipelineByPropertyName = $true, Position = 1)]
        [PSCredential]$Credential,

        # Sets the /admin switch on the mstsc command: Connects you to the session for administering a server
        [switch]$Admin,

        # Sets the /multimon switch on the mstsc command: Configures the Remote Desktop Services session monitor layout to be identical to the current client-side configuration
        [Parameter(ParameterSetName="MultiMonitorFullScreen")]
        [switch]$MultiMon,

        # Sets the /f switch on the mstsc command: Starts Remote Desktop in full-screen mode
        [Parameter(ParameterSetName="FullScreen")]
        [switch]$FullScreen,

        # Sets the /public switch on the mstsc command: Runs Remote Desktop in public mode
        [switch]$Public,

        # Sets the /w:<width> parameter on the mstsc command: Specifies the width of the Remote Desktop window
        [Parameter(ParameterSetName="Size")]
        [Alias('W','X')]
        [int]$Width,

        # Sets the /h:<height> parameter on the mstsc command: Specifies the height of the Remote Desktop window
        [Parameter(ParameterSetName="Size")]
        [Alias('H','Y')]
        [int]$Height,

        [switch]$Wait
    )

    begin {

        [string]$MstscArguments = -join $(
            switch ($true) {
                {$Admin}      { '/admin '     }
                {$MultiMon}   { '/multimon '  }
                {$FullScreen} { '/f '         }
                {$Public}     { '/public '    }
                {$Width}      { "/w:$Width "  }
                {$Height}     { "/h:$Height " }
            }
        )
    }
    process {
        foreach ($Computer in $ComputerName) {
            $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
            $Process = New-Object System.Diagnostics.Process

            # Remove the port number for CmdKey otherwise credentials are not entered correctly
            if ($Computer.Contains(':')) {
                $ComputerCmdkey = ($Computer -split ':')[0]
            } else {
                $ComputerCmdkey = $Computer
            }

            Set-Credential -Target TERMSRV/$ComputerCmdkey -ForceTarget -Credential $Credential -Type DomainPassword

            $ProcessInfo.FileName = "$($env:SystemRoot)\system32\mstsc.exe"
            $ProcessInfo.Arguments = "$MstscArguments /v $Computer"
            $ProcessInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Normal
            $Process.StartInfo = $ProcessInfo
            if ($PSCmdlet.ShouldProcess($Computer, 'Connecting mstsc')) {
                [void]$Process.Start()
                if ($Wait) {
                    $null = $Process.WaitForExit()
                }
            }
        }
    }
}