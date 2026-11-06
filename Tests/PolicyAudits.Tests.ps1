BeforeAll {
    Import-Module (Join-Path (Split-Path -Parent $PSScriptRoot) 'psEPM/psEPM.psd1') -Force
    $token = ConvertTo-SecureString 'fake-token' -AsPlainText -Force
    New-EPMSession -Token $token -BaseURI 'https://api.example.test'
}

Describe 'Get-EPMPolicyAudit' {
    It 'searches with an empty body and cursor paging' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ events = @([pscustomobject]@{ eventId = 'e-1'; eventType = 'Block'; setId = 'set-1' }); filteredCount = 1; returnedCount = 1; nextCursor = 'c' } }
        $result = Get-EPMPolicyAudit -SetId 'set-1'
        $result.SetId | Should -Be 'set-1'
        $result.eventId | Should -Be 'e-1'
        $result.PSObject.TypeNames[0] | Should -Be 'psEPM.PolicyAudit'
        @($result.PSObject.Properties | Where-Object Name -eq 'SetId').Count | Should -Be 1
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'POST' -and $Path -eq 'Sets/set-1/policyaudits/search?limit=1000&nextCursor=start' -and $Body.Count -eq 0
        }
    }

    It 'keeps the API setId property and adds SetId when it is missing' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ events = @([pscustomobject]@{ eventId = 'e-1'; setId = 'api-set' }, [pscustomobject]@{ eventId = 'e-2' }); filteredCount = 2; nextCursor = '' } }
        $result = @(Get-EPMPolicyAudit -SetId 'set-1')
        $result[0].PSObject.Properties['SetId'].Name | Should -BeExactly 'setId'
        $result[0].SetId | Should -Be 'api-set'
        $result[1].SetId | Should -Be 'set-1'
    }

    It 'builds arrivalTime and eventType IN clauses' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ events = @(); filteredCount = 0; nextCursor = $null } }
        $from = [datetime]::SpecifyKind([datetime]'2026-10-01T00:00:00', [System.DateTimeKind]::Utc)
        $to = [datetime]::SpecifyKind([datetime]'2026-10-31T23:59:59', [System.DateTimeKind]::Utc)
        Get-EPMPolicyAudit -SetId 'set-1' -DateFrom $from -DateTo $to -EventType Block, StartElevated
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter {
            $Body.filter -eq 'arrivalTime GE 2026-10-01T00:00:00Z AND arrivalTime LE 2026-10-31T23:59:59Z AND eventType IN Block,StartElevated'
        }
    }

    It 'uses IN for a single event type and adds a raw filter' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ events = @(); filteredCount = 0; nextCursor = $null } }
        Get-EPMPolicyAudit -SetId 'set-1' -EventType Block -Filter 'policyName CONTAINS "Block"'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter { $Body.filter -eq 'eventType IN Block AND policyName CONTAINS "Block"' }
    }

    It 'takes SetId from the pipeline and limits results with First' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ events = @(1..20 | ForEach-Object { [pscustomobject]@{ eventId = "e-$_" } }); filteredCount = 100; nextCursor = 'c' } }
        $result = @([pscustomobject]@{ SetId = 'set-2' } | Get-EPMPolicyAudit -First 10)
        $result.Count | Should -Be 10
        $result[0].SetId | Should -Be 'set-2'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter { $Path -eq 'Sets/set-2/policyaudits/search?limit=10&nextCursor=start' }
    }
}

Describe 'Get-EPMPolicyAuditAggregation' {
    It 'searches the aggregation path with a filter' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ events = @([pscustomobject]@{ aggregatedBy = 'h,Block'; eventType = 'Block' }); filteredCount = 1; nextCursor = 'c' } }
        $from = [datetime]::SpecifyKind([datetime]'2026-09-01T00:00:00', [System.DateTimeKind]::Utc)
        $result = Get-EPMPolicyAuditAggregation -SetId 'set-1' -DateFrom $from -EventType Block
        $result.SetId | Should -Be 'set-1'
        $result.PSObject.TypeNames[0] | Should -Be 'psEPM.PolicyAuditAggregation'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'POST' -and $Path -eq 'Sets/set-1/policyaudits/aggregations/search?limit=1000&nextCursor=start' -and $Body.filter -eq 'arrivalTime GE 2026-09-01T00:00:00Z AND eventType IN Block'
        }
    }

    It 'never sends an empty filter when no filter parameters are given' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ events = @(); filteredCount = 0; nextCursor = $null } }
        Get-EPMPolicyAuditAggregation -SetId 'set-1'
        Get-EPMPolicyAuditAggregation -SetId 'set-1' -Filter ''
        Get-EPMPolicyAuditAggregation -SetId 'set-1' -Filter '   '
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 3 -Exactly -ParameterFilter { $Body.Count -eq 0 -and -not $Body.ContainsKey('filter') }
    }

    It 'does not send sortBy or offset with the cursor' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ events = @(); filteredCount = 0; nextCursor = $null } }
        Get-EPMPolicyAuditAggregation -SetId 'set-1'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -ParameterFilter { $Path -like '*sortBy*' -or $Path -like '*offset*' } -Times 0 -Exactly
    }

    It 'stops and warns when the cursor repeats' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ events = @([pscustomobject]@{ aggregatedBy = 'a' }, [pscustomobject]@{ aggregatedBy = 'b' }); filteredCount = 5; nextCursor = 'same' } }
        $result = @(Get-EPMPolicyAuditAggregation -SetId 'set-1' -PageSize 2 -WarningVariable w -WarningAction SilentlyContinue)
        $result.Count | Should -Be 2
        @($w).Count | Should -Be 1
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 2 -Exactly
    }

    It 'takes SetId from the pipeline and limits results with First' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ events = @(1..5 | ForEach-Object { [pscustomobject]@{ aggregatedBy = "a$_" } }); filteredCount = 17; nextCursor = 'c' } }
        $result = @([pscustomobject]@{ SetId = 'set-3' } | Get-EPMPolicyAuditAggregation -First 3)
        $result.Count | Should -Be 3
        $result[0].SetId | Should -Be 'set-3'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter { $Path -eq 'Sets/set-3/policyaudits/aggregations/search?limit=3&nextCursor=start' }
    }
}
