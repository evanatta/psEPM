BeforeAll {
    Import-Module (Join-Path (Split-Path -Parent $PSScriptRoot) 'psEPM/psEPM.psd1') -Force
    $token = ConvertTo-SecureString 'fake-token' -AsPlainText -Force
    New-EPMSession -Token $token -BaseURI 'https://api.example.test'
}

Describe 'Get-EPMEndpointGroup' {
    It 'searches v2 with an empty filter and default sort' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod {
            [pscustomobject]@{ endpointGroups = @(
                    [pscustomobject]@{ id = 'g-1'; name = 'Lab'; type = 'Dynamic'; membersCount = 2 },
                    [pscustomobject]@{ id = 'g-2'; name = 'Kiosk'; type = 'Static'; membersCount = 0 }
                ); filteredCount = 2; returnedCount = 2 }
        }
        $result = @(Get-EPMEndpointGroup -SetId 'set-1')
        $result.Count | Should -Be 2
        $result[1].GroupId | Should -Be 'g-2'
        $result[0].SetId | Should -Be 'set-1'
        $result[0].PSObject.TypeNames[0] | Should -Be 'psEPM.EndpointGroup'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'POST' -and
            $Path -eq 'v2/Sets/set-1/Endpoints/groups/search?limit=1000&offset=0&sortBy=name&sortDir=desc' -and
            $Body.filter -eq ''
        }
    }

    It 'builds the filter from Name, Type and one GroupId' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ endpointGroups = @() } }
        Get-EPMEndpointGroup -SetId 'set-1' -GroupId 'g-1' -Name 'Lab' -Type Static -Filter 'description CONTAINS "x"'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -ParameterFilter {
            $Body.filter -eq 'description CONTAINS "x" AND id EQ "g-1" AND name CONTAINS "Lab" AND type EQ Static'
        }
    }

    It 'uses IN for several group IDs' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ endpointGroups = @() } }
        Get-EPMEndpointGroup -SetId 'set-1' -GroupId 'g-1', 'g-2' -SortBy Type -SortDirection asc
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -ParameterFilter {
            $Body.filter -eq 'id IN g-1,g-2' -and $Path -like '*sortBy=Type&sortDir=asc'
        }
    }

    It 'takes SetId and GroupId from the pipeline' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ endpointGroups = @([pscustomobject]@{ id = 'g-7'; name = 'A' }) } }
        $result = [pscustomobject]@{ SetId = 'set-2'; GroupId = 'g-7' } | Get-EPMEndpointGroup
        $result.SetId | Should -Be 'set-2'
        $result.GroupId | Should -Be 'g-7'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -ParameterFilter {
            $Path -like 'v2/Sets/set-2/*' -and $Body.filter -eq 'id EQ "g-7"'
        }
    }

    It 'falls back to v1 when v2 returns 404' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { throw 'EPM API POST v2 failed. HTTP 404  Not Found' } -ParameterFilter { $Path -like 'v2/*' }
        Mock -ModuleName psEPM Invoke-EPMRestMethod { , @([pscustomobject]@{ id = 'g-1'; name = 'Lab' }) } -ParameterFilter { $Path -like 'Sets/*' }
        $result = @(Get-EPMEndpointGroup -SetId 'set-1' -Name 'Lab')
        $result.Count | Should -Be 1
        $result[0].GroupId | Should -Be 'g-1'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter {
            $Path -like 'Sets/set-1/Endpoints/groups/search?*' -and $Body.filter -eq 'name CONTAINS "Lab"'
        }
    }

    It 'does not fall back on other errors' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { throw 'EPM API POST v2 failed. HTTP 400 EPM000002E Bad filter' } -ParameterFilter { $Path -like 'v2/*' }
        Mock -ModuleName psEPM Invoke-EPMRestMethod { , @() } -ParameterFilter { $Path -like 'Sets/*' }
        { Get-EPMEndpointGroup -SetId 'set-1' } | Should -Throw '*HTTP 400*'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 0 -Exactly -ParameterFilter { $Path -like 'Sets/*' }
    }
}

Describe 'Get-EPMEndpointGroupValue' {
    It 'posts the entity filter and returns each value' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { @([pscustomobject]@{ value = 'Windows 11' }, [pscustomobject]@{ value = 'macOS 15' }) }
        $result = @([pscustomobject]@{ SetId = 'set-1' } | Get-EPMEndpointGroupValue -Entity platformVersion)
        $result.value | Should -Be @('Windows 11', 'macOS 15')
        $result[0].SetId | Should -Be 'set-1'
        $result[0].Entity | Should -Be 'platformVersion'
        $result[0].PSObject.TypeNames[0] | Should -Be 'psEPM.EndpointGroupValue'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -ParameterFilter {
            $Method -eq 'POST' -and $Path -eq 'Sets/set-1/Endpoints/Groups/values/search' -and $Body.filter -eq 'entity EQ platformVersion'
        }
    }

    It 'handles a single value and an extra filter' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { , @([pscustomobject]@{ value = 'Windows' }) }
        $result = @(Get-EPMEndpointGroupValue -SetId 'set-1' -Entity platform -Filter 'value EQ Windows')
        $result.Count | Should -Be 1
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -ParameterFilter { $Body.filter -eq 'entity EQ platform AND value EQ Windows' }
    }

    It 'returns nothing for an empty array' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { , @() }
        @(Get-EPMEndpointGroupValue -SetId 'set-1' -Entity model).Count | Should -Be 0
    }

    It 'rejects unknown entities' {
        { Get-EPMEndpointGroupValue -SetId 'set-1' -Entity bogus } | Should -Throw
    }
}
