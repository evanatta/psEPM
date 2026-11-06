BeforeAll {
    Import-Module (Join-Path (Split-Path -Parent $PSScriptRoot) 'psEPM/psEPM.psd1') -Force
    $token = ConvertTo-SecureString 'fake-token' -AsPlainText -Force
    New-EPMSession -Token $token -BaseURI 'https://api.example.test'
}

Describe 'Get-EPMAgentPackage' {
    BeforeAll {
        Mock -ModuleName psEPM Invoke-EPMRestMethod {
            [pscustomobject]@{
                packages                  = @(
                    [pscustomobject]@{ id = 'pkg-1'; name = 'VFAgentSetupX64.msi'; packageOS = 'Windows'; packageType = 'latest'; releaseVersion = [pscustomobject]@{ _major = '26'; _minor = '10'; _build = '1'; _revision = '115' } },
                    [pscustomobject]@{ id = 'pkg-2'; name = 'VFAgentSetupX64.msi'; packageOS = 'Windows'; packageType = 'all'; releaseVersion = '26.8.3.113' }
                )
                linuxAgentPublicKey       = 'key'
                isDownloadStandaloneAgent = $false
            }
        }
    }

    It 'sends an empty filter when no criteria are given' {
        $result = @(Get-EPMAgentPackage -SetId 'set-1')
        $result.Count | Should -Be 2
        $result[0].PackageId | Should -Be 'pkg-1'
        $result[0].SetId | Should -Be 'set-1'
        $result[0].Version | Should -Be '26.10.1.115'
        $result[1].Version | Should -Be '26.8.3.113'
        $result[0].PSObject.TypeNames[0] | Should -Be 'psEPM.AgentPackage'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -ParameterFilter {
            $Method -eq 'POST' -and $Path -eq 'Sets/set-1/packages/search' -and $Body.ContainsKey('filter') -and $Body.filter -eq ''
        }
    }

    It 'builds the filter from parameters' {
        Get-EPMAgentPackage -SetId 'set-1' -PackageId 'a', 'b' -Platform MacOS, Linux | Out-Null
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -ParameterFilter {
            $Body.filter -eq 'id IN a,b AND platform IN MacOS,Linux'
        }
    }

    It 'uses EQ for a single platform' {
        Get-EPMAgentPackage -SetId 'set-1' -Platform Windows -Filter 'x EQ y' | Out-Null
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -ParameterFilter {
            $Body.filter -eq 'x EQ y AND platform EQ Windows'
        }
    }

    It 'returns only latest packages with -Latest' {
        @(Get-EPMAgentPackage -SetId 'set-1' -Latest).PackageId | Should -Be 'pkg-1'
    }

    It 'accepts SetId from the pipeline' {
        $result = @([pscustomobject]@{ SetId = 'set-2' } | Get-EPMAgentPackage)
        $result[0].SetId | Should -Be 'set-2'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -ParameterFilter { $Path -eq 'Sets/set-2/packages/search' }
    }
}

Describe 'Get-EPMEndpointPackage' {
    BeforeAll {
        Mock -ModuleName psEPM Invoke-EPMRestMethod {
            [pscustomobject]@{
                packages      = @([pscustomobject]@{ id = 'pkg-1'; name = 'VFAgentSetupX64.msi'; packageOS = 'Windows'; releaseVersion = [pscustomobject]@{ _major = '26'; _minor = '10'; _build = '1'; _revision = '115' } })
                filteredCount = 3
            }
        }
    }

    It 'posts the filter and adds set and count properties' {
        $result = Get-EPMEndpointPackage -SetId 'set-1' -Name 'PC' -Platform Windows
        $result.PackageId | Should -Be 'pkg-1'
        $result.SetId | Should -Be 'set-1'
        $result.FilteredCount | Should -Be 3
        $result.Version | Should -Be '26.10.1.115'
        $result.PSObject.TypeNames[0] | Should -Be 'psEPM.EndpointPackage'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -ParameterFilter {
            $Method -eq 'POST' -and $Path -eq 'Sets/set-1/Endpoints/Packages' -and $Body.filter -eq 'name CONTAINS "PC" AND platform EQ Windows'
        }
    }

    It 'takes SetId and EndpointId from the pipeline' {
        [pscustomobject]@{ SetId = 'set-1'; EndpointId = 'ep-1' } | Get-EPMEndpointPackage | Out-Null
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -ParameterFilter {
            $Path -eq 'Sets/set-1/Endpoints/Packages' -and $Body.filter -eq 'id IN ep-1'
        }
    }

    It 'returns nothing when the set has no packages' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ packages = @(); filteredCount = 0 } }
        @(Get-EPMEndpointPackage -SetId 'set-1').Count | Should -Be 0
    }
}

Describe 'Get-EPMPackageUrl' {
    It 'gets the URL for a piped package' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { 'https://files.example.test/pkg.msi' }
        $result = [pscustomobject]@{ SetId = 'set-1'; PackageId = 'pkg-1' } | Get-EPMPackageUrl
        $result.Url | Should -Be 'https://files.example.test/pkg.msi'
        $result.PackageId | Should -Be 'pkg-1'
        $result.SetId | Should -Be 'set-1'
        $result.PSObject.TypeNames[0] | Should -Be 'psEPM.PackageUrl'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -ParameterFilter { $Method -eq 'GET' -and $Path -eq 'Sets/set-1/packages/pkg-1/Url' }
    }
}

Describe 'Get-EPMPackageConfiguration' {
    BeforeAll {
        Mock -ModuleName psEPM Invoke-EPMRestMethod {
            [pscustomobject]@{
                Content = '{"setId":"set-1","setName":"Lab","version":"3"}'
                Headers = @{ installationkey = 'fake-install-key' }
            }
        }
    }

    It 'posts the documented body and returns the key and configuration' {
        $package = [pscustomobject]@{ SetId = 'set-1'; PackageId = 'pkg-1'; packageOS = 'Windows' }
        $result = $package | Get-EPMPackageConfiguration
        $result.InstallationKey | Should -Be 'fake-install-key'
        $result.Configuration.setName | Should -Be 'Lab'
        $result.Platform | Should -Be 'Windows'
        $result.PSObject.TypeNames[0] | Should -Be 'psEPM.PackageConfiguration'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -ParameterFilter {
            $Method -eq 'POST' -and
            $Path -eq 'Sets/set-1/packages/configuration' -and
            $IncludeResponseHeader -and
            $Body.platform -eq 'windows' -and
            $Body.packageId -eq 'pkg-1' -and
            $Body.includePolicies -eq $false
        }
    }

    It 'sends includePolicies and writes the raw configuration to a file' {
        $path = Join-Path $TestDrive 'agent.config'
        $result = Get-EPMPackageConfiguration -SetId 'set-1' -PackageId 'pkg-1' -Platform MacOS -IncludePolicies -OutFile $path
        $result.Path | Should -Be $path
        Get-Content -Path $path -Raw | Should -Be '{"setId":"set-1","setName":"Lab","version":"3"}'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -ParameterFilter {
            $Body.platform -eq 'macos' -and $Body.includePolicies -eq $true
        }
    }

    It 'rejects a platform the API does not accept' {
        { Get-EPMPackageConfiguration -SetId 'set-1' -PackageId 'pkg-1' -Platform Tools } | Should -Throw
    }
}

Describe 'Invoke-EPMRestMethod response headers' {
    It 'returns content and headers when asked' {
        Mock -ModuleName psEPM Invoke-WebRequest { [pscustomobject]@{ Content = '{}'; Headers = @{ installationKey = 'k' } } }
        $result = InModuleScope psEPM { Invoke-EPMRestMethod -Method POST -Path 'Sets/s1/packages/configuration' -Body @{} -IncludeResponseHeader }
        $result.Content | Should -Be '{}'
        $result.Headers.installationKey | Should -Be 'k'
        Should -Invoke -ModuleName psEPM Invoke-WebRequest -Times 1 -Exactly -ParameterFilter { $UseBasicParsing -and $Method -eq 'POST' }
    }
}

Describe 'Download center without a session' {
    It 'throws when no session exists' {
        Close-EPMSession
        { Get-EPMAgentPackage -SetId 'set-1' } | Should -Throw '*New-EPMSession*'
    }
}
