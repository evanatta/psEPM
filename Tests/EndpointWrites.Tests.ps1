BeforeAll {
    Import-Module (Join-Path (Split-Path -Parent $PSScriptRoot) 'psEPM/psEPM.psd1') -Force
    $token = ConvertTo-SecureString 'fake-token' -AsPlainText -Force
    New-EPMSession -Token $token -BaseURI 'https://api.example.test'
    $script:ep1 = '00000000-0000-0000-0000-00000000000a'
    $script:ep2 = '00000000-0000-0000-0000-00000000000b'
    $script:target = '00000000-0000-0000-0000-0000000000ff'
    $script:commands = @(
        @{ Name = 'Update-EPMEndpoint'; Extra = @{ Platform = 'Windows'; Architecture = 'x64'; Version = '26.10.1.115' } },
        @{ Name = 'Move-EPMEndpoint'; Extra = @{ TargetSetId = '00000000-0000-0000-0000-0000000000ff' } },
        @{ Name = 'Remove-EPMEndpoint'; Extra = @{} },
        @{ Name = 'Uninstall-EPMEndpoint'; Extra = @{} }
    )
}

Describe 'Endpoint write commands' {
    It '<Name> declares ShouldProcess with high impact and has no IncludeAll parameter' -TestCases @(
        @{ Name = 'Update-EPMEndpoint' }, @{ Name = 'Move-EPMEndpoint' }, @{ Name = 'Remove-EPMEndpoint' }, @{ Name = 'Uninstall-EPMEndpoint' }
    ) {
        param($Name)
        $meta = New-Object System.Management.Automation.CommandMetadata (Get-Command $Name)
        $meta.SupportsShouldProcess | Should -BeTrue
        $meta.ConfirmImpact | Should -Be 'High'
        (Get-Command $Name).Parameters.ContainsKey('IncludeAll') | Should -BeFalse
        (Get-Command $Name).Parameters['Filter'].Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] } | ForEach-Object { $_.ValueFromPipelineByPropertyName | Should -BeFalse }
    }

    It 'rejects a missing, empty, or blank filter without calling the API' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { throw 'should not be called' }
        foreach ($c in $script:commands) {
            $extra = $c.Extra
            { & $c.Name -SetId 'set-1' @extra -Confirm:$false } | Should -Throw '*empty filter*'
            { & $c.Name -SetId 'set-1' -Filter '' @extra -Confirm:$false } | Should -Throw '*empty filter*'
            { & $c.Name -SetId 'set-1' -Filter '   ' @extra -Confirm:$false } | Should -Throw '*empty filter*'
        }
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 0 -Exactly
    }

    It 'rejects an endpoint ID that is not a GUID' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { throw 'should not be called' }
        { Remove-EPMEndpoint -SetId 'set-1' -EndpointId 'x" OR name CONTAINS "a' -Confirm:$false } | Should -Throw
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 0 -Exactly
    }

    It 'makes no call with WhatIf' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { throw 'should not be called' }
        foreach ($c in $script:commands) {
            $extra = $c.Extra
            $result = & $c.Name -SetId 'set-1' -EndpointId $script:ep1 @extra -WhatIf
            $result | Should -BeNullOrEmpty
        }
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 0 -Exactly
    }
}

Describe 'Update-EPMEndpoint' {
    It 'posts the upgrade body with a versions array' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ appliedIds = @(); statuses = [pscustomobject]@{} } }
        $result = Update-EPMEndpoint -SetId 'set-1' -EndpointId $script:ep1 -Platform Windows -Architecture x64 -Version '26.10.1.115' -Confirm:$false -WarningAction SilentlyContinue
        $result.Action | Should -Be 'Upgrade'
        $result.PSObject.TypeNames[0] | Should -Be 'psEPM.EndpointChange'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter {
            if ($Method -ne 'POST' -or $Path -ne 'Sets/set-1/endpoints/upgrade' -or $Body -isnot [string]) { return $false }
            $Body -match '"versions":\[\{' -and $Body -match '"includeAll":false' -and $Body -match '"returnIds":true' -and
            (($Body | ConvertFrom-Json).filter -eq ('id EQ "{0}"' -f $script:ep1)) -and (($Body | ConvertFrom-Json).versions[0].architecture -eq 'x64')
        }
    }

    It 'rejects OS-style architecture values and a malformed version' {
        { Update-EPMEndpoint -SetId 'set-1' -EndpointId $script:ep1 -Platform Windows -Architecture OS_WIN64 -Version '26.10.1.115' -WhatIf } | Should -Throw
        { Update-EPMEndpoint -SetId 'set-1' -EndpointId $script:ep1 -Platform Windows -Architecture x64 -Version 'latest' -WhatIf } | Should -Throw
    }
}

Describe 'Move-EPMEndpoint' {
    It 'posts targetSet and returns TargetSetId' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ appliedIds = @($script:ep1); statuses = [pscustomobject]@{ OK = 1 } } }
        $result = Move-EPMEndpoint -SetId 'set-1' -EndpointId $script:ep1 -TargetSetId $script:target -Confirm:$false
        $result.Action | Should -Be 'Move'
        $result.TargetSetId | Should -Be $script:target
        @($result.AppliedIds).Count | Should -Be 1
        $result.Statuses.OK | Should -Be 1
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter {
            if ($Method -ne 'POST' -or $Path -ne 'Sets/set-1/Endpoints/moveset') { return $false }
            $b = $Body | ConvertFrom-Json
            $b.targetSet -eq $script:target -and $b.includeAll -eq $false -and $b.returnIds -eq $true
        }
    }

    It 'rejects a target set equal to the source set' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { throw 'should not be called' }
        { Move-EPMEndpoint -SetId $script:target -EndpointId $script:ep1 -TargetSetId $script:target -Confirm:$false } | Should -Throw '*different*'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 0 -Exactly
    }
}

Describe 'Remove-EPMEndpoint' {
    It 'sends force false by default and true with Force' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ appliedIds = @(); statuses = [pscustomobject]@{} } }
        Remove-EPMEndpoint -SetId 'set-1' -EndpointId $script:ep1 -Confirm:$false -WarningAction SilentlyContinue | Out-Null
        Remove-EPMEndpoint -SetId 'set-1' -EndpointId $script:ep1 -Force -Confirm:$false -WarningAction SilentlyContinue | Out-Null
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter { $Path -eq 'Sets/set-1/Endpoints/delete' -and ($Body | ConvertFrom-Json).force -eq $false }
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter { $Path -eq 'Sets/set-1/Endpoints/delete' -and ($Body | ConvertFrom-Json).force -eq $true }
    }

    It 'joins several IDs with IN and adds a raw filter' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ appliedIds = @(); statuses = [pscustomobject]@{} } }
        $result = Remove-EPMEndpoint -SetId 'set-1' -EndpointId $script:ep1, $script:ep2 -Filter 'connectionStatus EQ Disconnected' -Confirm:$false -WarningAction SilentlyContinue
        $result.Filter | Should -Be ('id IN {0},{1} AND connectionStatus EQ Disconnected' -f $script:ep1, $script:ep2)
        $result.Action | Should -Be 'Delete'
    }

    It 'takes SetId and EndpointId from piped endpoint rows' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ appliedIds = $script:ep1; statuses = [pscustomobject]@{ OK = 1 } } }
        $result = [pscustomobject]@{ SetId = 'set-2'; EndpointId = $script:ep1; Filter = 'name CONTAINS "x"' } | Remove-EPMEndpoint -Confirm:$false
        $result.SetId | Should -Be 'set-2'
        $result.Filter | Should -Be ('id EQ "{0}"' -f $script:ep1)
        @($result.AppliedIds) | Should -Be @($script:ep1)
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter { $Path -eq 'Sets/set-2/Endpoints/delete' }
    }
}

Describe 'Uninstall-EPMEndpoint' {
    It 'posts the uninstall body without force' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ appliedIds = @(); statuses = [pscustomobject]@{} } }
        $result = Uninstall-EPMEndpoint -SetId 'set-1' -Filter 'name EQ "APITEST_none"' -Confirm:$false -WarningAction SilentlyContinue
        $result.Action | Should -Be 'Uninstall'
        @($result.AppliedIds).Count | Should -Be 0
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter {
            if ($Method -ne 'POST' -or $Path -ne 'Sets/set-1/endpoints/uninstall') { return $false }
            $b = $Body | ConvertFrom-Json
            $b.filter -eq 'name EQ "APITEST_none"' -and $b.includeAll -eq $false -and $b.returnIds -eq $true -and $null -eq $b.PSObject.Properties['force']
        }
    }

    It 'warns when nothing was applied' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ appliedIds = @(); statuses = [pscustomobject]@{} } }
        Uninstall-EPMEndpoint -SetId 'set-1' -EndpointId $script:ep1 -Confirm:$false -WarningVariable w -WarningAction SilentlyContinue | Out-Null
        @($w).Count | Should -Be 1
    }
}
