BeforeAll {
    Import-Module (Join-Path (Split-Path -Parent $PSScriptRoot) 'psEPM/psEPM.psd1') -Force
    $token = ConvertTo-SecureString 'fake-token' -AsPlainText -Force
    New-EPMSession -Token $token -BaseURI 'https://api.example.test'
}

Describe 'Get-EPMApplicationCatalog' {
    It 'searches with an empty body and cursor paging' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ files = @([pscustomobject]@{ fileName = 'notepad.exe'; numOfComputers = 1 }); filteredCount = 1; returnedCount = 1; nextCursor = 'c' } }
        $result = Get-EPMApplicationCatalog -SetId 'set-1'
        $result.SetId | Should -Be 'set-1'
        $result.PSObject.TypeNames[0] | Should -Be 'psEPM.ApplicationCatalog'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'POST' -and $Path -eq 'Sets/set-1/Files/Aggregations/search?limit=1000&nextCursor=start' -and $Body.Count -eq 0 -and -not $Body.ContainsKey('filter')
        }
    }

    It 'builds the operatingSystemType filter and joins a raw filter' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ files = @(); filteredCount = 0; nextCursor = $null } }
        Get-EPMApplicationCatalog -SetId 'set-1' -OperatingSystem MacOS
        Get-EPMApplicationCatalog -SetId 'set-1' -OperatingSystem Windows -Filter 'fileName CONTAINS "pad"'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter { $Body.filter -ceq 'operatingSystemType EQ MacOS' }
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter { $Body.filter -ceq 'operatingSystemType EQ Windows AND fileName CONTAINS "pad"' }
    }

    It 'never sends an empty filter' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ files = @(); filteredCount = 0; nextCursor = $null } }
        Get-EPMApplicationCatalog -SetId 'set-1' -Filter ''
        Get-EPMApplicationCatalog -SetId 'set-1' -Filter '  '
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 2 -Exactly -ParameterFilter { $Body.Count -eq 0 }
    }

    It 'rejects an unknown operating system' {
        { Get-EPMApplicationCatalog -SetId 'set-1' -OperatingSystem 'None' } | Should -Throw
    }

    It 'stops and warns when the cursor returns the first page again' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ files = @([pscustomobject]@{ n = 1 }, [pscustomobject]@{ n = 2 }); filteredCount = 10; nextCursor = 'again' } }
        $result = @(Get-EPMApplicationCatalog -SetId 'set-1' -PageSize 2 -WarningVariable w -WarningAction SilentlyContinue)
        $result.Count | Should -Be 2
        @($w).Count | Should -Be 1
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 2 -Exactly
    }

    It 'makes one sorted call without a cursor' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ files = @([pscustomobject]@{ n = 1 }); filteredCount = 5; nextCursor = $null } }
        $result = @(Get-EPMApplicationCatalog -SetId 'set-1' -SortBy NumOfComputers -OperatingSystem Linux -WarningVariable w -WarningAction SilentlyContinue)
        $result.Count | Should -Be 1
        @($w).Count | Should -Be 1
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'POST' -and $Path -eq 'Sets/set-1/Files/Aggregations/search?limit=1000&sortBy=NumOfComputers&sortDir=desc' -and $Body.filter -eq 'operatingSystemType EQ Linux'
        }
    }

    It 'uses First as the limit on a sorted call' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ files = @(1..3 | ForEach-Object { [pscustomobject]@{ n = $_ } }); filteredCount = 50; nextCursor = $null } }
        $result = @(Get-EPMApplicationCatalog -SetId 'set-1' -SortBy FirstSeen -SortDirection asc -First 3)
        $result.Count | Should -Be 3
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter { $Path -eq 'Sets/set-1/Files/Aggregations/search?limit=3&sortBy=FirstSeen&sortDir=asc' }
    }

    It 'takes SetId from the pipeline and limits results with First' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ files = @(1..10 | ForEach-Object { [pscustomobject]@{ n = $_ } }); filteredCount = 100; nextCursor = 'c' } }
        $result = @([pscustomobject]@{ SetId = 'set-2' } | Get-EPMApplicationCatalog -First 4)
        $result.Count | Should -Be 4
        $result[0].SetId | Should -Be 'set-2'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter { $Path -eq 'Sets/set-2/Files/Aggregations/search?limit=4&nextCursor=start' }
    }

    It 'keeps the API setId property' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ files = @([pscustomobject]@{ setId = 'api-set' }); filteredCount = 1; nextCursor = '' } }
        $result = Get-EPMApplicationCatalog -SetId 'set-1'
        $result.PSObject.Properties['SetId'].Name | Should -BeExactly 'setId'
    }
}

Describe 'Get-EPMFileInstance' {
    It 'searches the file instance path with an empty body' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ fileInstances = @([pscustomobject]@{ fileName = 'notepad.exe' }); filteredCount = 1; nextCursor = 'c' } }
        $result = Get-EPMFileInstance -SetId 'set-1'
        $result.SetId | Should -Be 'set-1'
        $result.PSObject.TypeNames[0] | Should -Be 'psEPM.FileInstance'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'POST' -and $Path -eq 'Sets/set-1/Files/FileInstances/Search?limit=1000&nextCursor=start' -and $Body.Count -eq 0
        }
    }

    It 'builds arrivalTime clauses and adds a raw filter' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ fileInstances = @(); filteredCount = 0; nextCursor = $null } }
        $from = [datetime]::SpecifyKind([datetime]'2026-09-01T00:00:00', [System.DateTimeKind]::Utc)
        $to = [datetime]::SpecifyKind([datetime]'2026-09-30T23:59:59', [System.DateTimeKind]::Utc)
        Get-EPMFileInstance -SetId 'set-1' -DateFrom $from -DateTo $to -Filter 'operatingSystemType EQ Windows'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter {
            $Body.filter -eq 'arrivalTime GE 2026-09-01T00:00:00Z AND arrivalTime LE 2026-09-30T23:59:59Z AND operatingSystemType EQ Windows'
        }
    }

    It 'pages with the cursor until it is empty' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod {
            if ($Path -like '*nextCursor=start') { return [pscustomobject]@{ fileInstances = @([pscustomobject]@{ n = 1 }, [pscustomobject]@{ n = 2 }); filteredCount = 3; nextCursor = 'p2' } }
            [pscustomobject]@{ fileInstances = @([pscustomobject]@{ n = 3 }); filteredCount = 3; nextCursor = $null }
        }
        $result = @(Get-EPMFileInstance -SetId 'set-1' -PageSize 2)
        $result.Count | Should -Be 3
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter { $Path -eq 'Sets/set-1/Files/FileInstances/Search?limit=2&nextCursor=p2' }
    }

    It 'takes SetId from the pipeline and limits results with First' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ fileInstances = @(1..10 | ForEach-Object { [pscustomobject]@{ n = $_ } }); filteredCount = 100; nextCursor = 'c' } }
        $result = @([pscustomobject]@{ SetId = 'set-3' } | Get-EPMFileInstance -First 5)
        $result.Count | Should -Be 5
        $result[0].SetId | Should -Be 'set-3'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter { $Path -eq 'Sets/set-3/Files/FileInstances/Search?limit=5&nextCursor=start' }
    }
}
