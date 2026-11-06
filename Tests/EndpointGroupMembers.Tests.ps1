BeforeAll {
    Import-Module (Join-Path (Split-Path -Parent $PSScriptRoot) 'psEPM/psEPM.psd1') -Force
    $token = ConvertTo-SecureString 'fake-token' -AsPlainText -Force
    New-EPMSession -Token $token -BaseURI 'https://api.example.test'
}

Describe 'ConvertTo-EPMMemberIdBody' {
    It 'writes a JSON array for one ID' {
        InModuleScope psEPM {
            $json = ConvertTo-EPMMemberIdBody -Id 'ep-1'
            $json | Should -Be '{"membersIds":["ep-1"]}'
            ,(($json | ConvertFrom-Json).membersIds) | Should -BeOfType [array]
        }
    }

    It 'writes a JSON array for several IDs' {
        InModuleScope psEPM { ConvertTo-EPMMemberIdBody -Id 'a', 'b' | Should -Be '{"membersIds":["a","b"]}' }
    }
}

Describe 'Add-EPMEndpointGroupMember' {
    It 'adds one endpoint by ID with a JSON array body' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { , @('ep-1') }
        $result = Add-EPMEndpointGroupMember -SetId 'set-1' -GroupId 'g-1' -EndpointId 'ep-1'
        $result.AppliedIds | Should -Be @('ep-1')
        $result.RequestedIds | Should -Be @('ep-1')
        $result.Action | Should -Be 'Add'
        $result.SetId | Should -Be 'set-1'
        $result.GroupId | Should -Be 'g-1'
        $result.PSObject.TypeNames[0] | Should -Be 'psEPM.EndpointGroupMemberChange'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'POST' -and $Path -eq 'Sets/set-1/Endpoints/Groups/g-1/members/ids' -and
            $Body -is [string] -and $Body -eq '{"membersIds":["ep-1"]}'
        }
    }

    It 'maps a one-item response that arrives as a plain string' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { 'ep-1' }
        $result = Add-EPMEndpointGroupMember -SetId 'set-1' -GroupId 'g-1' -EndpointId 'ep-1'
        @($result.AppliedIds) | Should -Be @('ep-1')
    }

    It 'maps an empty response to no applied IDs' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { '' }
        $result = Add-EPMEndpointGroupMember -SetId 'set-1' -GroupId 'g-1' -Filter 'id EQ "x"'
        @($result.AppliedIds).Count | Should -Be 0
    }

    It 'sends piped endpoints in one request' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { , @('ep-1', 'ep-2') }
        $result = @(
            [pscustomobject]@{ SetId = 'set-1'; EndpointId = 'ep-1' },
            [pscustomobject]@{ SetId = 'set-1'; EndpointId = 'ep-2' },
            [pscustomobject]@{ SetId = 'set-1'; EndpointId = 'ep-1' }
        ) | Add-EPMEndpointGroupMember -GroupId 'g-1'
        @($result).Count | Should -Be 1
        $result.RequestedIds | Should -Be @('ep-1', 'ep-2')
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter { $Body -eq '{"membersIds":["ep-1","ep-2"]}' }
    }

    It 'adds by filter with override false by default' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { , @() }
        $result = [pscustomobject]@{ SetId = 'set-1'; GroupId = 'g-1' } | Add-EPMEndpointGroupMember -Filter 'name EQ "PC1"'
        @($result.AppliedIds).Count | Should -Be 0
        $result.Filter | Should -Be 'name EQ "PC1"'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -ParameterFilter {
            $Method -eq 'POST' -and $Path -eq 'Sets/set-1/Endpoints/Groups/g-1/members' -and
            $Body.filter -eq 'name EQ "PC1"' -and $Body.override -eq $false
        }
    }

    It 'sends override true with -Override' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { , @('ep-1') }
        Add-EPMEndpointGroupMember -SetId 'set-1' -GroupId 'g-1' -Filter 'id EQ "ep-1"' -Override -Confirm:$false
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -ParameterFilter { $Body.override -eq $true }
    }

    It 'rejects an empty or blank filter' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { }
        { Add-EPMEndpointGroupMember -SetId 'set-1' -GroupId 'g-1' -Filter '' } | Should -Throw
        { Add-EPMEndpointGroupMember -SetId 'set-1' -GroupId 'g-1' -Filter '  ' } | Should -Throw '*non-empty*'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 0 -Exactly
    }

    It 'does not call the API with -WhatIf' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { }
        Add-EPMEndpointGroupMember -SetId 'set-1' -GroupId 'g-1' -EndpointId 'ep-1' -WhatIf
        Add-EPMEndpointGroupMember -SetId 'set-1' -GroupId 'g-1' -Filter 'id EQ "ep-1"' -WhatIf
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 0 -Exactly
    }
}

Describe 'Remove-EPMEndpointGroupMember' {
    It 'removes one endpoint by ID with a JSON array body and wraps the boolean result' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { $true }
        $result = Remove-EPMEndpointGroupMember -SetId 'set-1' -GroupId 'g-1' -EndpointId 'ep-1' -Confirm:$false
        $result | Should -Not -BeOfType [bool]
        $result.Action | Should -Be 'Remove'
        $result.RequestedIds | Should -Be @('ep-1')
        @($result.AppliedIds).Count | Should -Be 0
        $result.PSObject.TypeNames[0] | Should -Be 'psEPM.EndpointGroupMemberChange'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'POST' -and $Path -eq 'Sets/set-1/Endpoints/Groups/g-1/members/ids/remove' -and $Body -eq '{"membersIds":["ep-1"]}'
        }
    }

    It 'takes SetId, GroupId and EndpointId from the pipeline' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { $true }
        [pscustomobject]@{ SetId = 'set-2'; GroupId = 'g-2'; EndpointId = 'ep-9' } | Remove-EPMEndpointGroupMember -Confirm:$false
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -ParameterFilter { $Path -eq 'Sets/set-2/Endpoints/Groups/g-2/members/ids/remove' -and $Body -eq '{"membersIds":["ep-9"]}' }
    }

    It 'removes by filter' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { , @('ep-1') }
        $result = Remove-EPMEndpointGroupMember -SetId 'set-1' -GroupId 'g-1' -Filter 'id EQ "ep-1"' -Confirm:$false
        $result.AppliedIds | Should -Be @('ep-1')
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -ParameterFilter {
            $Method -eq 'POST' -and $Path -eq 'Sets/set-1/Endpoints/Groups/g-1/members/remove' -and $Body.filter -eq 'id EQ "ep-1"' -and -not $Body.ContainsKey('override')
        }
    }

    It 'rejects an empty or blank filter' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { }
        { Remove-EPMEndpointGroupMember -SetId 'set-1' -GroupId 'g-1' -Filter '' -Confirm:$false } | Should -Throw
        { Remove-EPMEndpointGroupMember -SetId 'set-1' -GroupId 'g-1' -Filter ' ' -Confirm:$false } | Should -Throw '*non-empty*'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 0 -Exactly
    }

    It 'does not call the API with -WhatIf' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { }
        Remove-EPMEndpointGroupMember -SetId 'set-1' -GroupId 'g-1' -EndpointId 'ep-1' -WhatIf
        Remove-EPMEndpointGroupMember -SetId 'set-1' -GroupId 'g-1' -Filter 'id EQ "ep-1"' -WhatIf
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 0 -Exactly
    }

    It 'has a high confirm impact' {
        $meta = New-Object System.Management.Automation.CommandMetadata (Get-Command Remove-EPMEndpointGroupMember)
        $meta.ConfirmImpact | Should -Be 'High'
    }
}
