BeforeAll {
    Import-Module (Join-Path (Split-Path -Parent $PSScriptRoot) 'psEPM/psEPM.psd1') -Force
    $token = ConvertTo-SecureString 'fake-token' -AsPlainText -Force
    New-EPMSession -Token $token -BaseURI 'https://api.example.test'
}

Describe 'Invoke-EPMPagedRequest cursor mode' {
    It 'sends limit and nextCursor start and follows the cursor' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod {
            if ($Path -like '*nextCursor=start') { return [pscustomobject]@{ events = @([pscustomobject]@{ n = 1 }, [pscustomobject]@{ n = 2 }); filteredCount = 3; nextCursor = 'a/b+c' } }
            [pscustomobject]@{ events = @([pscustomobject]@{ n = 3 }); filteredCount = 3; nextCursor = '' }
        }
        $result = InModuleScope psEPM { Invoke-EPMPagedRequest -Method POST -Path 'Sets/s/Events/Search' -ItemProperty events -Body @{} -PageSize 2 -Cursor }
        @($result).Count | Should -Be 3
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter { $Path -eq 'Sets/s/Events/Search?limit=2&nextCursor=start' }
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter { $Path -eq 'Sets/s/Events/Search?limit=2&nextCursor=a%2Fb%2Bc' }
    }

    It 'stops when filteredCount is reached even if a cursor is returned' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ events = @([pscustomobject]@{ n = 1 }, [pscustomobject]@{ n = 2 }); filteredCount = 2; nextCursor = 'more' } }
        $result = InModuleScope psEPM { Invoke-EPMPagedRequest -Method POST -Path 'p' -ItemProperty events -Body @{} -Cursor }
        @($result).Count | Should -Be 2
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly
    }

    It 'stops when the cursor repeats and drops a repeated page' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ events = @([pscustomobject]@{ n = 1 }); filteredCount = 3; nextCursor = 'same' } }
        $result = InModuleScope psEPM { Invoke-EPMPagedRequest -Method POST -Path 'p' -ItemProperty events -Body @{} -PageSize 1 -Cursor -WarningVariable w -WarningAction SilentlyContinue; $w }
        @($result | Where-Object { $_ -isnot [System.Management.Automation.WarningRecord] }).Count | Should -Be 1
        @($result | Where-Object { $_ -is [System.Management.Automation.WarningRecord] }).Count | Should -Be 1
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 2 -Exactly
    }

    It 'stops when nextCursor is null' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ events = @([pscustomobject]@{ n = 1 }); filteredCount = 5; nextCursor = $null } }
        $result = InModuleScope psEPM { Invoke-EPMPagedRequest -Method POST -Path 'p' -ItemProperty events -Body @{} -Cursor -WarningAction SilentlyContinue }
        @($result).Count | Should -Be 1
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly
    }

    It 'uses First as the limit when it is smaller than the page size' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ events = @(1..5 | ForEach-Object { [pscustomobject]@{ n = $_ } }); filteredCount = 50; nextCursor = 'x' } }
        $result = InModuleScope psEPM { Invoke-EPMPagedRequest -Method POST -Path 'p' -ItemProperty events -Body @{} -First 5 -Cursor }
        @($result).Count | Should -Be 5
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter { $Path -eq 'p?limit=5&nextCursor=start' }
    }

    It 'returns nothing for an empty result' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ events = @(); filteredCount = 0; nextCursor = $null } }
        $result = InModuleScope psEPM { Invoke-EPMPagedRequest -Method POST -Path 'p' -ItemProperty events -Body @{} -Cursor }
        @($result).Count | Should -Be 0
    }
}

Describe 'Get-EPMEvent' {
    It 'searches with an empty body and cursor paging' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ events = @([pscustomobject]@{ eventId = 'e-1'; eventType = 'Trust' }); filteredCount = 1; nextCursor = 'c' } }
        $result = Get-EPMEvent -SetId 'set-1'
        $result.SetId | Should -Be 'set-1'
        $result.EventId | Should -Be 'e-1'
        $result.PSObject.TypeNames[0] | Should -Be 'psEPM.Event'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'POST' -and $Path -eq 'Sets/set-1/Events/Search?limit=1000&nextCursor=start' -and $Body.Count -eq 0
        }
    }

    It 'builds arrivalTime and eventType IN clauses' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ events = @(); filteredCount = 0; nextCursor = $null } }
        $from = [datetime]::SpecifyKind([datetime]'2026-10-01T05:06:07', [System.DateTimeKind]::Utc)
        $to = [datetime]::SpecifyKind([datetime]'2026-10-31T23:59:59', [System.DateTimeKind]::Utc)
        Get-EPMEvent -SetId 'set-1' -DateFrom $from -DateTo $to -EventType Trust, Block -Filter 'fileName CONTAINS "x"'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter {
            $Body.filter -eq 'arrivalTime GE 2026-10-01T05:06:07Z AND arrivalTime LE 2026-10-31T23:59:59Z AND eventType IN Trust,Block AND fileName CONTAINS "x"'
        }
    }

    It 'uses IN for a single event type' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ events = @(); filteredCount = 0; nextCursor = $null } }
        Get-EPMEvent -SetId 'set-1' -EventType Trust
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter { $Body.filter -eq 'eventType IN Trust' -and $Body.filter -notlike '*EQ*' }
    }

    It 'rejects an unknown event type' {
        { Get-EPMEvent -SetId 'set-1' -EventType 'ALL' } | Should -Throw
    }

    It 'takes SetId from the pipeline' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ events = @(); filteredCount = 0; nextCursor = $null } }
        [pscustomobject]@{ SetId = 'set-2' } | Get-EPMEvent -First 10
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter { $Path -eq 'Sets/set-2/Events/Search?limit=10&nextCursor=start' }
    }
}

Describe 'Get-EPMEventAggregation' {
    It 'searches the lowercase events aggregation path' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ events = @([pscustomobject]@{ eventType = 'Trust'; fileName = 'a.exe' }); filteredCount = 1; nextCursor = 'c' } }
        $result = Get-EPMEventAggregation -SetId 'set-1' -EventType Launch
        $result.SetId | Should -Be 'set-1'
        $result.PSObject.TypeNames[0] | Should -Be 'psEPM.EventAggregation'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'POST' -and $Path -eq 'Sets/set-1/events/aggregations/search?limit=1000&nextCursor=start' -and $Body.filter -eq 'eventType IN Launch'
        }
    }

    It 'does not send sortBy with the cursor' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ events = @(); filteredCount = 0; nextCursor = $null } }
        Get-EPMEventAggregation -SetId 'set-1'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -ParameterFilter { $Path -like '*sortBy*' } -Times 0 -Exactly
    }
}
