Describe FlexibleSecretNames {
    BeforeAll {
        $ModuleName = "BetterCredentials.Extension"
        $VaultName = "BetterCredentialsTestVault"
        $PSModulePath = $Env:PSModulePath
        $Env:PSModulePath = "$(Convert-Path $PSScriptRoot\..\..)$([IO.Path]::PathSeparator)$PSModulePath"
        Remove-Module BetterCredentials, $ModuleName -ErrorAction SilentlyContinue
        Import-Module -Name BetterCredentials
        # Import-Module -Name Microsoft.PowerShell.SecretManagement
        Import-Module (Get-Module BetterCredentials | Split-Path | Join-Path -ChildPath "$ModuleName\$ModuleName.psd1")


        $FixTarget, $FixName = InModuleScope BetterCredentials.Extension {
            Get-Command FixTarget, FixName
        }
    }

    Context FixTarget {
        It "FixTarget returns BetterCredentials|VaultName|Name by default" {
            $Parameters = @{
                Filter = "*"
                VaultName = "TestVault"
                AdditionalParameters = @{}
            }

            & $FixTarget @Parameters | Should -Be "BetterCredentials|TestVault|*"
        }
    }

    Context FixName {
        It "Trims BetterCredentials|VaultName| by default" {
            $Parameters = @{
                Filter = "*"
                VaultName = "TestVault"
                AdditionalParameters = @{}
            }

            [PSCustomObject]@{
                Target = "BetterCredentials|TestVault|SomeName"
            } | & $FixName @Parameters | Should -Be "SomeName"
        }
    }

    Context "BackwardCompatibility" {
        It "Supports Setting MicrosoftPowerShell:user=" {
            $Parameters = @{
                Name                 = "Jaykul@HuddledMasses.org"
                VaultName            = "TestVault"
                AdditionalParameters = @{
                    Namespace = "MicrosoftPowerShell"
                    VaultName  = "user"
                    Separator  = "="
                }
            }


            & $FixTarget @Parameters | Should -Be "MicrosoftPowerShell:user=Jaykul@HuddledMasses.org"
        }

        It "Supports searching MicrosoftPowerShell:user=" {
            $Parameters = @{
                VaultName            = "TestVault"
                AdditionalParameters = @{
                    Namespace = "MicrosoftPowerShell"
                    VaultName = "user"
                    Separator = "="
                }
            }

            & $FixTarget @Parameters | Should -Be "MicrosoftPowerShell:user=*"
        }

        It "Supports getting MicrosoftPowerShell:user=" {
            $Parameters = @{
                Name                 = "Jaykul@HuddledMasses.org"
                VaultName            = "TestVault"
                AdditionalParameters = @{
                    Namespace = "MicrosoftPowerShell"
                    VaultName  = "user"
                    Separator  = "="
                }
            }

            [PSCustomObject]@{
                Target = "MicrosoftPowerShell:user=Jaykul@HuddledMasses.org"
            } | & $FixName @Parameters | Should -Be "Jaykul@HuddledMasses.org"
        }
    }
}