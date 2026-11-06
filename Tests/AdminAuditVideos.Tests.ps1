BeforeAll {
    Import-Module (Join-Path (Split-Path -Parent $PSScriptRoot) 'psEPM/psEPM.psd1') -Force
    $token = ConvertTo-SecureString 'fake-token' -AsPlainText -Force
    New-EPMSession -Token $token -BaseURI 'https://api.example.test'
}

Describe 'Get-EPMAdminAudit' {
    It 'gets with DateFrom, DateTo, offset, and limit and no body' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ TotalCount = 1; AdminAudits = @([pscustomobject]@{ Feature = 'POLICIES'; Description = 'x' }) } }
        $from = [datetime]::SpecifyKind([datetime]'2026-10-01T00:00:00', [System.DateTimeKind]::Utc)
        $to = [datetime]::SpecifyKind([datetime]'2026-10-31T23:59:59', [System.DateTimeKind]::Utc)
        $result = Get-EPMAdminAudit -SetId 'set-1' -DateFrom $from -DateTo $to
        $result.SetId | Should -Be 'set-1'
        $result.PSObject.TypeNames[0] | Should -Be 'psEPM.AdminAudit'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'GET' -and $Path -ceq 'Sets/set-1/AdminAudit?DateFrom=2026-10-01T00%3A00%3A00Z&DateTo=2026-10-31T23%3A59%3A59Z&limit=500&offset=0' -and -not $PSBoundParameters.ContainsKey('Body')
        }
    }

    It 'converts DateFrom to UTC' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ TotalCount = 0; AdminAudits = @() } }
        $from = [datetimeoffset]::new(2026, 10, 1, 6, 0, 0, [timespan]::FromHours(-5)).UtcDateTime
        Get-EPMAdminAudit -SetId 'set-1' -DateFrom $from -DateTo $from.AddDays(1)
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter { $Path -clike '*DateFrom=2026-10-01T11%3A00%3A00Z&DateTo=2026-10-02T11%3A00%3A00Z*' }
    }

    It 'pins DateTo to the current time when only DateFrom is given' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ TotalCount = 0; AdminAudits = @() } }
        $before = [datetime]::UtcNow.AddSeconds(-1).ToString('yyyy-MM-ddTHH:mm:ss', [System.Globalization.CultureInfo]::InvariantCulture)
        Get-EPMAdminAudit -SetId 'set-1' -DateFrom ([datetime]::UtcNow.AddDays(-30))
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter {
            $m = [regex]::Match($Path, 'DateTo=([^&]+)')
            $m.Success -and ([uri]::UnescapeDataString($m.Groups[1].Value) -ge $before)
        }
    }

    It 'sends the last day when no dates are given' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ TotalCount = 0; AdminAudits = @() } }
        Get-EPMAdminAudit -SetId 'set-1'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter {
            $culture = [System.Globalization.CultureInfo]::InvariantCulture
            $f = [regex]::Match($Path, 'DateFrom=([^&]+)'); $t = [regex]::Match($Path, 'DateTo=([^&]+)')
            $from = [datetime]::ParseExact([uri]::UnescapeDataString($f.Groups[1].Value), 'yyyy-MM-ddTHH:mm:ssZ', $culture, [System.Globalization.DateTimeStyles]::AdjustToUniversal)
            $to = [datetime]::ParseExact([uri]::UnescapeDataString($t.Groups[1].Value), 'yyyy-MM-ddTHH:mm:ssZ', $culture, [System.Globalization.DateTimeStyles]::AdjustToUniversal)
            $f.Success -and $t.Success -and ($to - $from) -eq [timespan]::FromDays(1)
        }
    }

    It 'sends only DateTo when only DateTo is given' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ TotalCount = 0; AdminAudits = @() } }
        Get-EPMAdminAudit -SetId 'set-1' -DateTo ([datetime]::SpecifyKind([datetime]'2026-10-31T00:00:00', [System.DateTimeKind]::Utc))
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter { $Path -ceq 'Sets/set-1/AdminAudit?DateTo=2026-10-31T00%3A00%3A00Z&limit=500&offset=0' }
    }

    It 'pages with offset' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod {
            if ($Path -like '*offset=0*') { return [pscustomobject]@{ TotalCount = 3; AdminAudits = @([pscustomobject]@{ n = 1 }, [pscustomobject]@{ n = 2 }) } }
            [pscustomobject]@{ TotalCount = 3; AdminAudits = @([pscustomobject]@{ n = 3 }) }
        }
        $result = @(Get-EPMAdminAudit -SetId 'set-1' -PageSize 2)
        $result.Count | Should -Be 3
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter { $Path -like '*limit=2&offset=2' }
    }

    It 'rejects a page size over 500' {
        { Get-EPMAdminAudit -SetId 'set-1' -PageSize 501 } | Should -Throw
    }

    It 'takes SetId from the pipeline and limits results with First' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ TotalCount = 50; AdminAudits = @(1..10 | ForEach-Object { [pscustomobject]@{ n = $_ } }) } }
        $result = @([pscustomobject]@{ SetId = 'set-2' } | Get-EPMAdminAudit -First 3)
        $result.Count | Should -Be 3
        $result[0].SetId | Should -Be 'set-2'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter { $Path -clike 'Sets/set-2/AdminAudit?*' }
    }
}

Describe 'Get-EPMVideo' {
    It 'searches with POST and an empty body' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ videos = @([pscustomobject]@{ status = 'Video Available' }); filteredCount = 1; returnedCount = 1; nextCursor = $null } }
        $result = Get-EPMVideo -SetId 'set-1'
        $result.SetId | Should -Be 'set-1'
        $result.PSObject.TypeNames[0] | Should -Be 'psEPM.Video'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'POST' -and $Path -eq 'Sets/set-1/Videos/Search?limit=1000&nextCursor=start' -and $Body.Count -eq 0
        }
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 0 -Exactly -ParameterFilter { $Method -eq 'GET' }
    }

    It 'sends a filter and skips a blank one' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ videos = @(); filteredCount = 0; nextCursor = $null } }
        Get-EPMVideo -SetId 'set-1' -Filter 'startTime GE 2026-10-01T00:00:00Z'
        Get-EPMVideo -SetId 'set-1' -Filter ' '
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter { $Body.filter -eq 'startTime GE 2026-10-01T00:00:00Z' }
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter { $Body.Count -eq 0 }
    }

    It 'keeps an existing setId property' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ videos = @([pscustomobject]@{ setId = 'api-set' }); filteredCount = 1; nextCursor = $null } }
        $result = Get-EPMVideo -SetId 'set-1'
        $result.PSObject.Properties['SetId'].Name | Should -BeExactly 'setId'
    }

    It 'takes SetId from the pipeline and limits results with First' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ videos = @(1..5 | ForEach-Object { [pscustomobject]@{ n = $_ } }); filteredCount = 9; nextCursor = 'c' } }
        $result = @([pscustomobject]@{ SetId = 'set-3' } | Get-EPMVideo -First 2)
        $result.Count | Should -Be 2
        $result[0].SetId | Should -Be 'set-3'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter { $Path -eq 'Sets/set-3/Videos/Search?limit=2&nextCursor=start' }
    }
}
