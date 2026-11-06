BeforeAll {
    Import-Module (Join-Path (Split-Path -Parent $PSScriptRoot) 'psEPM/psEPM.psd1') -Force
    $token = ConvertTo-SecureString 'fake-token' -AsPlainText -Force
    New-EPMSession -Token $token -BaseURI 'https://api.example.test'
}

Describe 'Get-EPMEndpointInventory' {
    It 'posts an empty filter for all endpoints and returns the array items' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod {
            @(
                [pscustomobject]@{ id = 'ep-1'; name = 'PC1'; inventory = [pscustomobject]@{ osInfo = @{} } },
                [pscustomobject]@{ id = 'ep-2'; name = 'PC2'; inventory = [pscustomobject]@{ osInfo = @{} } }
            )
        }
        $result = @(Get-EPMEndpointInventory -SetId 'set-1' -InventoryType OsInfo)
        $result.Count | Should -Be 2
        $result[1].EndpointId | Should -Be 'ep-2'
        $result[0].SetId | Should -Be 'set-1'
        $result[0].InventoryType | Should -Be 'OsInfo'
        $result[0].PSObject.TypeNames[0] | Should -Be 'psEPM.EndpointInventory'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'POST' -and
            $Path -like 'Sets/set-1/Endpoints/inventory/OsInfo?limit=1000&offset=0' -and
            $Body.filter -eq ''
        }
    }

    It 'returns a single item array as one object' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { , @([pscustomobject]@{ id = 'ep-1'; inventory = @{} }) }
        $result = @(Get-EPMEndpointInventory -SetId 'set-1' -InventoryType Hardware)
        $result.Count | Should -Be 1
        $result[0].EndpointId | Should -Be 'ep-1'
    }

    It 'makes one call per inventory type' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { @([pscustomobject]@{ id = 'ep-1'; inventory = @{} }) }
        $result = @(Get-EPMEndpointInventory -SetId 'set-1' -InventoryType UserGroups, InstalledPrograms)
        $result.InventoryType | Should -Be @('UserGroups', 'InstalledPrograms')
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter { $Path -like 'Sets/set-1/Endpoints/inventory/UserGroups?*' }
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter { $Path -like 'Sets/set-1/Endpoints/inventory/InstalledPrograms?*' }
    }

    It 'takes SetId and EndpointId from the pipeline and filters by endpointId' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { @([pscustomobject]@{ id = 'ep-9'; inventory = @{} }) }
        $result = [pscustomobject]@{ SetId = 'set-2'; EndpointId = 'ep-9' } | Get-EPMEndpointInventory -InventoryType Network
        $result.SetId | Should -Be 'set-2'
        $result.EndpointId | Should -Be 'ep-9'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -ParameterFilter {
            $Path -like 'Sets/set-2/Endpoints/inventory/Network?*' -and $Body.filter -eq 'endpointId EQ "ep-9"'
        }
    }

    It 'joins EndpointId and Filter with AND' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { @() }
        Get-EPMEndpointInventory -SetId 'set-1' -InventoryType DomainInfo -EndpointId 'ep-1' -Filter 'platform EQ Windows'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -ParameterFilter {
            $Body.filter -eq 'endpointId EQ "ep-1" AND platform EQ Windows'
        }
    }

    It 'returns nothing for an empty array' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { , @() }
        @(Get-EPMEndpointInventory -SetId 'set-1' -InventoryType TimeAndDate).Count | Should -Be 0
    }

    It 'pages until a short page is returned' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { @([pscustomobject]@{ id = 'a' }, [pscustomobject]@{ id = 'b' }) } -ParameterFilter { $Path -like '*offset=0' }
        Mock -ModuleName psEPM Invoke-EPMRestMethod { @([pscustomobject]@{ id = 'c' }) } -ParameterFilter { $Path -like '*offset=2' }
        $result = @(Get-EPMEndpointInventory -SetId 'set-1' -InventoryType OsInfo -PageSize 2)
        $result.EndpointId | Should -Be @('a', 'b', 'c')
    }

    It 'rejects inventory types from the details API' {
        { Get-EPMEndpointInventory -SetId 'set-1' -InventoryType UserGroupsInfo } | Should -Throw
    }
}

Describe 'Get-EPMEndpointSummary' {
    It 'gets the summary rows with SetId added' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod {
            [pscustomobject]@{ summary = @(
                    [pscustomobject]@{ agentVersion = '26.8.2.143'; platform = 'Windows'; endpointsCount = 4; versionSupported = $true },
                    [pscustomobject]@{ agentVersion = '26.10.0.189'; platform = 'MacOS'; endpointsCount = 1; versionSupported = $true }
                ) }
        }
        $result = @([pscustomobject]@{ SetId = 'set-1' } | Get-EPMEndpointSummary)
        $result.Count | Should -Be 2
        $result[0].SetId | Should -Be 'set-1'
        $result[0].endpointsCount | Should -Be 4
        $result[0].PSObject.TypeNames[0] | Should -Be 'psEPM.EndpointSummary'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -ParameterFilter {
            $Method -eq 'GET' -and $Path -eq 'Sets/set-1/Endpoints/Summary' -and -not $PSBoundParameters.ContainsKey('Body')
        }
    }

    It 'returns nothing for a set with no endpoints' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ summary = @() } }
        @(Get-EPMEndpointSummary -SetId 'set-1').Count | Should -Be 0
    }
}
