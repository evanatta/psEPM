BeforeAll {
    Import-Module (Join-Path (Split-Path -Parent $PSScriptRoot) 'psEPM/psEPM.psd1') -Force
    $token = ConvertTo-SecureString 'fake-token' -AsPlainText -Force
    New-EPMSession -Token $token -BaseURI 'https://api.example.test'
}

Describe 'Get-EPMSignInAudit' {
    It 'searches with an empty body and cursor paging' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ events = @([pscustomobject]@{ loginResult = $true; policyName = 'Sign-in policy' }); filteredCount = 1; returnedCount = 1; nextCursor = 'c' } }
        $result = Get-EPMSignInAudit -SetId 'set-1'
        $result.SetId | Should -Be 'set-1'
        $result.PSObject.TypeNames[0] | Should -Be 'psEPM.SignInAudit'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'POST' -and $Path -eq 'Sets/set-1/signinaudits/search?limit=1000&nextCursor=start' -and $Body.Count -eq 0
        }
    }

    It 'builds arrivalTime clauses and adds a raw filter' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ events = @(); filteredCount = 0; nextCursor = $null } }
        $from = [datetime]::SpecifyKind([datetime]'2026-10-01T00:00:00', [System.DateTimeKind]::Utc)
        $to = [datetime]::SpecifyKind([datetime]'2026-10-31T23:59:59', [System.DateTimeKind]::Utc)
        Get-EPMSignInAudit -SetId 'set-1' -DateFrom $from -DateTo $to -Filter 'loginType EQ "EPMLT_ONLINE"'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter {
            $Body.filter -eq 'arrivalTime GE 2026-10-01T00:00:00Z AND arrivalTime LE 2026-10-31T23:59:59Z AND loginType EQ "EPMLT_ONLINE"'
        }
    }

    It 'has no EventType parameter' {
        (Get-Command Get-EPMSignInAudit).Parameters.ContainsKey('EventType') | Should -BeFalse
    }

    It 'keeps the API setId property' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ events = @([pscustomobject]@{ setId = 'api-set' }); filteredCount = 1; nextCursor = '' } }
        $result = Get-EPMSignInAudit -SetId 'set-1'
        $result.PSObject.Properties['SetId'].Name | Should -BeExactly 'setId'
        $result.SetId | Should -Be 'api-set'
    }

    It 'takes SetId from the pipeline and limits results with First' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ events = @(1..10 | ForEach-Object { [pscustomobject]@{ n = $_ } }); filteredCount = 40; nextCursor = 'c' } }
        $result = @([pscustomobject]@{ SetId = 'set-2' } | Get-EPMSignInAudit -First 4)
        $result.Count | Should -Be 4
        $result[0].SetId | Should -Be 'set-2'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter { $Path -eq 'Sets/set-2/signinaudits/search?limit=4&nextCursor=start' }
    }
}

Describe 'Get-EPMSignInAuditAggregation' {
    It 'searches the aggregation path with an empty body' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ events = @([pscustomobject]@{ loginResult = $false; totalEvents = 2 }); filteredCount = 1; nextCursor = 'c' } }
        $result = Get-EPMSignInAuditAggregation -SetId 'set-1'
        $result.SetId | Should -Be 'set-1'
        $result.PSObject.TypeNames[0] | Should -Be 'psEPM.SignInAuditAggregation'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'POST' -and $Path -eq 'Sets/set-1/signinaudits/aggregations/search?limit=1000&nextCursor=start' -and $Body.Count -eq 0 -and -not $Body.ContainsKey('filter')
        }
    }

    It 'never sends an empty filter' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ events = @(); filteredCount = 0; nextCursor = $null } }
        Get-EPMSignInAuditAggregation -SetId 'set-1' -Filter ''
        Get-EPMSignInAuditAggregation -SetId 'set-1' -Filter '  '
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 2 -Exactly -ParameterFilter { $Body.Count -eq 0 }
    }

    It 'adds a quoted loginResult clause' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ events = @(); filteredCount = 0; nextCursor = $null } }
        Get-EPMSignInAuditAggregation -SetId 'set-1' -LoginResult $true
        Get-EPMSignInAuditAggregation -SetId 'set-1' -LoginResult $false
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter { $Body.filter -ceq 'loginResult EQ "true"' }
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter { $Body.filter -ceq 'loginResult EQ "false"' }
    }

    It 'joins dates, loginResult, and a raw filter' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ events = @(); filteredCount = 0; nextCursor = $null } }
        $from = [datetime]::SpecifyKind([datetime]'2026-09-01T00:00:00', [System.DateTimeKind]::Utc)
        Get-EPMSignInAuditAggregation -SetId 'set-1' -DateFrom $from -LoginResult $false -Filter 'platform EQ "EPMP_WINDOWS"'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter {
            $Body.filter -ceq 'arrivalTime GE 2026-09-01T00:00:00Z AND loginResult EQ "false" AND platform EQ "EPMP_WINDOWS"'
        }
    }

    It 'does not send sortBy or offset with the cursor' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ events = @(); filteredCount = 0; nextCursor = $null } }
        Get-EPMSignInAuditAggregation -SetId 'set-1'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -ParameterFilter { $Path -like '*sortBy*' -or $Path -like '*offset*' } -Times 0 -Exactly
    }

    It 'takes SetId from the pipeline and limits results with First' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ events = @(1..5 | ForEach-Object { [pscustomobject]@{ n = $_ } }); filteredCount = 9; nextCursor = 'c' } }
        $result = @([pscustomobject]@{ SetId = 'set-3' } | Get-EPMSignInAuditAggregation -First 2)
        $result.Count | Should -Be 2
        $result[0].SetId | Should -Be 'set-3'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter { $Path -eq 'Sets/set-3/signinaudits/aggregations/search?limit=2&nextCursor=start' }
    }
}
