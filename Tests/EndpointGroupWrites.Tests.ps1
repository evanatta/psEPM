BeforeAll {
    Import-Module (Join-Path (Split-Path -Parent $PSScriptRoot) 'psEPM/psEPM.psd1') -Force
    $token = ConvertTo-SecureString 'fake-token' -AsPlainText -Force
    New-EPMSession -Token $token -BaseURI 'https://api.example.test'
}

Describe 'New-EPMEndpointGroup' {
    It 'creates a static group' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ id = 'g-1'; type = 'Static'; name = 'Lab'; description = 'Test'; membersCount = 0 } }
        $result = New-EPMEndpointGroup -SetId 'set-1' -Name 'Lab' -Type Static -Description 'Test' -Confirm:$false
        $result.GroupId | Should -Be 'g-1'
        $result.SetId | Should -Be 'set-1'
        $result.PSObject.TypeNames[0] | Should -Be 'psEPM.EndpointGroup'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'POST' -and $Path -eq 'Sets/set-1/Endpoints/Groups' -and
            $Body.type -eq 'Static' -and $Body.name -eq 'Lab' -and $Body.description -eq 'Test' -and -not $Body.ContainsKey('filter')
        }
    }

    It 'creates a dynamic group with a filter and takes SetId from the pipeline' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ id = 'g-2'; type = 'Dynamic'; name = 'Win'; filter = 'platform EQ Windows' } }
        $result = [pscustomobject]@{ SetId = 'set-2' } | New-EPMEndpointGroup -Name 'Win' -Type Dynamic -Filter 'platform EQ Windows'
        $result.SetId | Should -Be 'set-2'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -ParameterFilter {
            $Path -eq 'Sets/set-2/Endpoints/Groups' -and $Body.filter -eq 'platform EQ Windows' -and -not $Body.ContainsKey('description')
        }
    }

    It 'requires a filter for a dynamic group' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { }
        { New-EPMEndpointGroup -SetId 'set-1' -Name 'Win' -Type Dynamic } | Should -Throw '*requires -Filter*'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 0 -Exactly
    }

    It 'rejects a filter for a static group' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { }
        { New-EPMEndpointGroup -SetId 'set-1' -Name 'Lab' -Type Static -Filter 'platform EQ Windows' } | Should -Throw '*only to Dynamic*'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 0 -Exactly
    }

    It 'does not call the API with -WhatIf' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { }
        New-EPMEndpointGroup -SetId 'set-1' -Name 'Lab' -Type Static -WhatIf
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 0 -Exactly
    }
}

Describe 'Set-EPMEndpointGroup' {
    BeforeEach {
        Mock -ModuleName psEPM Invoke-EPMRestMethod {
            [pscustomobject]@{ endpointGroups = @([pscustomobject]@{ id = 'g-1'; type = 'Static'; name = 'Lab'; description = 'Old' }) }
        } -ParameterFilter { $Path -like 'v2/*' }
        Mock -ModuleName psEPM Invoke-EPMRestMethod {
            [pscustomobject]@{ id = $Body.id; type = $Body.type; name = $Body.name; description = $Body.description; membersCount = 0 }
        } -ParameterFilter { $Method -eq 'PUT' }
    }

    It 'merges changes into the current group and sends the full object' {
        $result = [pscustomobject]@{ SetId = 'set-1'; GroupId = 'g-1' } | Set-EPMEndpointGroup -Description 'New' -Confirm:$false
        $result.GroupId | Should -Be 'g-1'
        $result.SetId | Should -Be 'set-1'
        $result.PSObject.TypeNames[0] | Should -Be 'psEPM.EndpointGroup'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'PUT' -and $Path -eq 'Sets/set-1/Endpoints/groups' -and
            $Body.id -eq 'g-1' -and $Body.type -eq 'Static' -and $Body.name -eq 'Lab' -and $Body.description -eq 'New'
        }
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter { $Path -like 'v2/Sets/set-1/Endpoints/groups/search*' -and $Body.filter -eq 'id EQ "g-1"' }
    }

    It 'keeps the description when only the name changes' {
        Set-EPMEndpointGroup -SetId 'set-1' -GroupId 'g-1' -Name 'Lab2'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -ParameterFilter { $Method -eq 'PUT' -and $Body.name -eq 'Lab2' -and $Body.description -eq 'Old' }
    }

    It 'clears the description with an empty string' {
        Set-EPMEndpointGroup -SetId 'set-1' -GroupId 'g-1' -Description ''
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -ParameterFilter { $Method -eq 'PUT' -and -not $Body.ContainsKey('description') }
    }

    It 'rejects a filter on a static group' {
        { Set-EPMEndpointGroup -SetId 'set-1' -GroupId 'g-1' -Filter 'platform EQ Windows' } | Should -Throw '*only to Dynamic*'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 0 -Exactly -ParameterFilter { $Method -eq 'PUT' }
    }

    It 'keeps or replaces the filter of a dynamic group' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod {
            [pscustomobject]@{ endpointGroups = @([pscustomobject]@{ id = 'g-2'; type = 'Dynamic'; name = 'Win'; filter = 'platform EQ Windows' }) }
        } -ParameterFilter { $Path -like 'v2/*' }
        Set-EPMEndpointGroup -SetId 'set-1' -GroupId 'g-2' -Description 'd'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -ParameterFilter { $Method -eq 'PUT' -and $Body.filter -eq 'platform EQ Windows' }
        Set-EPMEndpointGroup -SetId 'set-1' -GroupId 'g-2' -Filter 'platform EQ MacOS'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -ParameterFilter { $Method -eq 'PUT' -and $Body.filter -eq 'platform EQ MacOS' -and $Body.type -eq 'Dynamic' }
    }

    It 'throws when the group is not found' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ endpointGroups = @() } } -ParameterFilter { $Path -like 'v2/*' }
        { Set-EPMEndpointGroup -SetId 'set-1' -GroupId 'g-9' -Name 'X' } | Should -Throw '*not found*'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 0 -Exactly -ParameterFilter { $Method -eq 'PUT' }
    }

    It 'does not call the API with -WhatIf' {
        Set-EPMEndpointGroup -SetId 'set-1' -GroupId 'g-1' -Name 'X' -WhatIf
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 0 -Exactly
    }
}

Describe 'Remove-EPMEndpointGroup' {
    BeforeEach {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ appliedIds = @('g-1'); attachedPolicies = [pscustomobject]@{} } }
    }

    It 'deletes one group by ID' {
        $result = Remove-EPMEndpointGroup -SetId 'set-1' -GroupId 'g-1' -Confirm:$false
        $result.AppliedIds | Should -Be @('g-1')
        $result.SetId | Should -Be 'set-1'
        $result.Filter | Should -Be 'id EQ "g-1"'
        $result.PSObject.TypeNames[0] | Should -Be 'psEPM.EndpointGroupRemoval'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'POST' -and $Path -eq 'Sets/set-1/Endpoints/groups/delete' -and $Body.filter -eq 'id EQ "g-1"'
        }
    }

    It 'uses IN for several IDs and joins a filter with AND' {
        Remove-EPMEndpointGroup -SetId 'set-1' -GroupId 'g-1', 'g-2' -Filter 'name CONTAINS "Lab"' -Confirm:$false
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -ParameterFilter { $Body.filter -eq 'id IN g-1,g-2 AND name CONTAINS "Lab"' }
    }

    It 'takes SetId and GroupId from the pipeline' {
        [pscustomobject]@{ SetId = 'set-3'; GroupId = 'g-3'; filter = 'platform EQ Windows' } | Remove-EPMEndpointGroup -Confirm:$false
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -ParameterFilter { $Path -eq 'Sets/set-3/Endpoints/groups/delete' -and $Body.filter -eq 'id EQ "g-3"' }
    }

    It 'deletes by filter only' {
        Remove-EPMEndpointGroup -SetId 'set-1' -Filter 'name CONTAINS "Old"' -Confirm:$false
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -ParameterFilter { $Body.filter -eq 'name CONTAINS "Old"' }
    }

    It 'rejects an empty or blank filter' {
        { Remove-EPMEndpointGroup -SetId 'set-1' -Filter '' -Confirm:$false } | Should -Throw
        { Remove-EPMEndpointGroup -SetId 'set-1' -Filter '   ' -Confirm:$false } | Should -Throw '*non-empty*'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 0 -Exactly
    }

    It 'rejects an empty group ID' {
        { Remove-EPMEndpointGroup -SetId 'set-1' -GroupId '' -Confirm:$false } | Should -Throw
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 0 -Exactly
    }

    It 'warns when nothing matched' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ appliedIds = @(); attachedPolicies = [pscustomobject]@{} } }
        $result = Remove-EPMEndpointGroup -SetId 'set-1' -GroupId 'g-9' -Confirm:$false -WarningVariable warn -WarningAction SilentlyContinue
        @($result.AppliedIds).Count | Should -Be 0
        $warn.Count | Should -Be 1
    }

    It 'does not call the API with -WhatIf' {
        Remove-EPMEndpointGroup -SetId 'set-1' -GroupId 'g-1' -WhatIf
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 0 -Exactly
    }

    It 'has a high confirm impact' {
        $meta = New-Object System.Management.Automation.CommandMetadata (Get-Command Remove-EPMEndpointGroup)
        $meta.ConfirmImpact | Should -Be 'High'
        $meta.SupportsShouldProcess | Should -BeTrue
    }
}
