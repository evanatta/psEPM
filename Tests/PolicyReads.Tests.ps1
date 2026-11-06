BeforeAll {
    Import-Module (Join-Path (Split-Path -Parent $PSScriptRoot) 'psEPM/psEPM.psd1') -Force
    $token = ConvertTo-SecureString 'fake-token' -AsPlainText -Force
    New-EPMSession -Token $token -BaseURI 'https://api.example.test'
}

Describe 'Get-EPMAgentConfiguration' {
    It 'searches with POST and an empty body' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ Policies = @([pscustomobject]@{ PolicyId = 'c-1'; PolicyName = 'General configuration'; PolicyType = 45 }) } }
        $result = Get-EPMAgentConfiguration -SetId 'set-1'
        $result.AgentConfigurationId | Should -Be 'c-1'
        $result.SetId | Should -Be 'set-1'
        $result.PSObject.TypeNames[0] | Should -Be 'psEPM.AgentConfiguration'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'POST' -and $Path -eq 'Sets/set-1/Policies/AgentConfiguration/Search?limit=1000&offset=0&sortBy=Name&sortDir=asc' -and $Body.Count -eq 0
        }
    }

    It 'filters by name with PolicyName' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ Policies = @() } }
        Get-EPMAgentConfiguration -SetId 'set-1' -Name 'General'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -ParameterFilter { $Body.filter -eq 'PolicyName CONTAINS "General"' }
    }

    It 'gets the default with one AgentConfiguration segment' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ Id = 'set-1'; Name = 'General configuration'; PolicyType = 44 } }
        $result = [pscustomobject]@{ SetId = 'set-1' } | Get-EPMAgentConfiguration -Default
        $result.AgentConfigurationId | Should -Be 'set-1'
        $result.PSObject.TypeNames[0] | Should -Be 'psEPM.AgentConfigurationDefinition'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'GET' -and $Path -eq 'Sets/set-1/Policies/AgentConfiguration/Default' -and $Path -notlike '*AgentConfiguration/AgentConfiguration*' -and -not $PSBoundParameters.ContainsKey('Body')
        }
    }

    It 'gets details from a piped search row' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ Policy = [pscustomobject]@{ Id = 'c-1'; PolicyType = 44 } } }
        $result = [pscustomobject]@{ SetId = 'set-1'; PolicyId = 'c-1' } | Get-EPMAgentConfiguration
        $result.AgentConfigurationId | Should -Be 'c-1'
        $result.PSObject.TypeNames[0] | Should -Be 'psEPM.AgentConfigurationDetail'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -ParameterFilter { $Method -eq 'GET' -and $Path -eq 'Sets/set-1/Policies/AgentConfiguration/c-1' }
    }
}

Describe 'Get-EPMThreatProtectionPolicy' {
    BeforeEach {
        Mock -ModuleName psEPM Invoke-EPMRestMethod {
            , @(
                [pscustomobject]@{ Id = 't-1'; Name = 'Block credential dump'; CategoryName = 'Credentials'; PolicyType = 50 },
                [pscustomobject]@{ Id = 't-2'; Name = 'Protect browser'; CategoryName = 'Browsers'; PolicyType = 50 }
            )
        }
    }

    It 'returns one object per policy with SetId' {
        $result = @([pscustomobject]@{ SetId = 'set-1' } | Get-EPMThreatProtectionPolicy)
        $result.Count | Should -Be 2
        $result[0].SetId | Should -Be 'set-1'
        $result[0].PolicyId | Should -Be 't-1'
        $result[0].PSObject.TypeNames[0] | Should -Be 'psEPM.ThreatProtectionPolicy'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -ParameterFilter { $Method -eq 'GET' -and $Path -eq 'Sets/set-1/Policies/ThreatProtection' -and -not $PSBoundParameters.ContainsKey('Body') }
    }

    It 'filters by name and category wildcards' {
        @(Get-EPMThreatProtectionPolicy -SetId 'set-1' -Name '*browser*').Id | Should -Be 't-2'
        @(Get-EPMThreatProtectionPolicy -SetId 'set-1' -Category 'Cred*').Id | Should -Be 't-1'
    }
}

Describe 'Get-EPMPolicyRecommendation' {
    It 'returns one object per recommendation from Data' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod {
            [pscustomobject]@{ Data = @([pscustomobject]@{ Type = 'WellKnownApplications' }, [pscustomobject]@{ Type = 'WindowsRecommendedBlockRules' }); TotalCount = 2 }
        }
        $result = @([pscustomobject]@{ SetId = 'set-1' } | Get-EPMPolicyRecommendation)
        $result.Type | Should -Be @('WellKnownApplications', 'WindowsRecommendedBlockRules')
        $result[0].SetId | Should -Be 'set-1'
        $result[0].PSObject.TypeNames[0] | Should -Be 'psEPM.PolicyRecommendation'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -ParameterFilter { $Method -eq 'GET' -and $Path -eq 'Sets/set-1/Policies/Recommendations' }
    }

    It 'returns nothing when Data is empty' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ Data = @(); TotalCount = 0 } }
        @(Get-EPMPolicyRecommendation -SetId 'set-1').Count | Should -Be 0
    }
}
