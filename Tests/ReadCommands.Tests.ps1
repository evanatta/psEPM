BeforeAll {
    Import-Module (Join-Path (Split-Path -Parent $PSScriptRoot) 'psEPM/psEPM.psd1') -Force
    $token = ConvertTo-SecureString 'fake-token' -AsPlainText -Force
    New-EPMSession -Token $token -BaseURI 'https://api.example.test'
}

Describe 'Get-EPMSet' {
    BeforeAll {
        Mock -ModuleName psEPM Invoke-EPMRestMethod {
            [pscustomobject]@{ Sets = @(
                    [pscustomobject]@{ Id = 'set-1'; Name = 'Lab One' },
                    [pscustomobject]@{ Id = 'set-2'; Name = 'Prod' }
                ) }
        }
    }

    It 'returns all sets with SetId added' {
        $sets = @(Get-EPMSet)
        $sets.Count | Should -Be 2
        $sets[0].SetId | Should -Be 'set-1'
        $sets[0].PSObject.TypeNames[0] | Should -Be 'psEPM.Set'
    }

    It 'filters by name with wildcards' {
        @(Get-EPMSet -Name 'Lab*').Name | Should -Be 'Lab One'
    }

    It 'accepts SetId from the pipeline' {
        ([pscustomobject]@{ SetId = 'set-2' } | Get-EPMSet).Name | Should -Be 'Prod'
    }
}

Describe 'Get-EPMEndpoint' {
    It 'builds the search filter from parameters' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ endpoints = @([pscustomobject]@{ id = 'ep-1'; name = 'PC1' }) } }
        $result = Get-EPMEndpoint -SetId 'set-1' -Name 'PC' -Platform Windows, MacOS
        $result.EndpointId | Should -Be 'ep-1'
        $result.SetId | Should -Be 'set-1'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -ParameterFilter {
            $Method -eq 'POST' -and
            $Path -like 'Sets/set-1/Endpoints/search?*limit=1000*offset=0*' -and
            $Body.filter -eq 'name CONTAINS "PC" AND platform IN Windows,MacOS'
        }
    }

    It 'gets endpoint details from pipeline input' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ id = 'ep-1'; inventory = @{} } }
        $detail = [pscustomobject]@{ SetId = 'set-1'; EndpointId = 'ep-1' } | Get-EPMEndpoint -InventoryType OsInfo, Hardware
        $detail.PSObject.TypeNames[0] | Should -Be 'psEPM.EndpointDetail'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -ParameterFilter {
            $Path -eq 'Sets/set-1/Endpoints/ep-1/search' -and $Body.filter -eq 'inventoryType IN OsInfo,Hardware'
        }
    }
}

Describe 'Get-EPMPolicy' {
    It 'searches policies with an empty body when no filter is given' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ Policies = @([pscustomobject]@{ PolicyId = 'p1'; PolicyName = 'Test' }) } }
        (Get-EPMPolicy -SetId 'set-1').PolicyId | Should -Be 'p1'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -ParameterFilter {
            $Path -like 'Sets/set-1/Policies/Server/Search?*' -and $Body.Count -eq 0
        }
    }

    It 'gets policy details by id from the pipeline' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ Policy = @{ Name = 'Test' } } }
        $detail = [pscustomobject]@{ SetId = 'set-1'; PolicyId = 'p1' } | Get-EPMPolicy
        $detail.PSObject.TypeNames[0] | Should -Be 'psEPM.PolicyDetail'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -ParameterFilter { $Method -eq 'GET' -and $Path -eq 'Sets/set-1/Policies/Server/p1' }
    }
}
