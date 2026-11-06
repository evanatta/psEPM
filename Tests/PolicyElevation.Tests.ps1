BeforeAll {
    Import-Module (Join-Path (Split-Path -Parent $PSScriptRoot) 'psEPM/psEPM.psd1') -Force
    $token = ConvertTo-SecureString 'fake-token' -AsPlainText -Force
    New-EPMSession -Token $token -BaseURI 'https://api.example.test'
}

Describe 'Set-EPMPolicyElevation' {
    It 'approves with POST, Elevation 1, and SendEmail false by default' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ Id = 'p-1'; Name = 'Temporary elevation' } }
        $result = Set-EPMPolicyElevation -SetId 'set-1' -AggregatedBy '16,32' -Elevation Approve -Confirm:$false
        $result.SetId | Should -Be 'set-1'
        $result.Id | Should -Be 'p-1'
        $result.PSObject.TypeNames[0] | Should -Be 'psEPM.PolicyElevation'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'POST' -and $Path -eq 'Sets/set-1/Policies/Server/Elevate' -and $Body -ceq '{"SendEmail":false,"Filter":"aggregatedBy EQ \"16,32\"","Elevation":1}'
        }
    }

    It 'rejects with DELETE and Elevation 2' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { $null }
        $result = Set-EPMPolicyElevation -SetId 'set-1' -AggregatedBy 'ABC,ElevationRequest' -Elevation Reject -Confirm:$false
        $result.Elevation | Should -Be 'Reject'
        $result.Filter | Should -Be 'aggregatedBy EQ "ABC,ElevationRequest"'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'DELETE' -and $Path -eq 'Sets/set-1/Policies/Server/Elevate' -and ($Body | ConvertFrom-Json).Elevation -eq 2 -and ($Body | ConvertFrom-Json).SendEmail -eq $false
        }
    }

    It 'sends SendEmail true only with the switch' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { $null }
        Set-EPMPolicyElevation -SetId 'set-1' -AggregatedBy '16,32' -Elevation Approve -SendEmail -Confirm:$false | Out-Null
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter { ($Body | ConvertFrom-Json).SendEmail -eq $true }
    }

    It 'uses a raw filter and joins it to AggregatedBy' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { $null }
        Set-EPMPolicyElevation -SetId 'set-1' -Filter 'aggregatedBy IN "16,32"' -Elevation Reject -Confirm:$false | Out-Null
        Set-EPMPolicyElevation -SetId 'set-1' -AggregatedBy '16,32' -Filter 'x EQ "y"' -Elevation Approve -Confirm:$false | Out-Null
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter { ($Body | ConvertFrom-Json).Filter -eq 'aggregatedBy IN "16,32"' }
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter { ($Body | ConvertFrom-Json).Filter -eq 'aggregatedBy EQ "16,32" AND x EQ "y"' }
    }

    It 'rejects a missing or blank filter and a quoted AggregatedBy without calling the API' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { throw 'should not be called' }
        { Set-EPMPolicyElevation -SetId 'set-1' -Elevation Approve -Confirm:$false } | Should -Throw '*empty filter*'
        { Set-EPMPolicyElevation -SetId 'set-1' -Filter '  ' -Elevation Approve -Confirm:$false } | Should -Throw '*empty filter*'
        { Set-EPMPolicyElevation -SetId 'set-1' -AggregatedBy 'a" OR x EQ "b' -Elevation Approve -Confirm:$false } | Should -Throw
        { Set-EPMPolicyElevation -SetId 'set-1' -AggregatedBy '16,32' -Elevation 1 -Confirm:$false } | Should -Throw
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 0 -Exactly
    }

    It 'makes no call with WhatIf' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { throw 'should not be called' }
        Set-EPMPolicyElevation -SetId 'set-1' -AggregatedBy '16,32' -Elevation Approve -WhatIf | Should -BeNullOrEmpty
        Set-EPMPolicyElevation -SetId 'set-1' -AggregatedBy '16,32' -Elevation Reject -WhatIf | Should -BeNullOrEmpty
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 0 -Exactly
    }

    It 'declares ShouldProcess with high impact' {
        $meta = New-Object System.Management.Automation.CommandMetadata (Get-Command Set-EPMPolicyElevation)
        $meta.SupportsShouldProcess | Should -BeTrue
        $meta.ConfirmImpact | Should -Be 'High'
    }

    It 'takes SetId and AggregatedBy from the pipeline but not Filter' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { $null }
        [pscustomobject]@{ SetId = 'set-2'; aggregatedBy = 'ABC,ElevationRequest'; Filter = 'name EQ "x"' } | Set-EPMPolicyElevation -Elevation Approve -Confirm:$false | Out-Null
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter {
            $Path -eq 'Sets/set-2/Policies/Server/Elevate' -and ($Body | ConvertFrom-Json).Filter -eq 'aggregatedBy EQ "ABC,ElevationRequest"'
        }
    }
}
