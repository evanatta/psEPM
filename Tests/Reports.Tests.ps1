BeforeAll {
    Import-Module (Join-Path (Split-Path -Parent $PSScriptRoot) 'psEPM/psEPM.psd1') -Force
    $token = ConvertTo-SecureString 'fake-token' -AsPlainText -Force
    New-EPMSession -Token $token -BaseURI 'https://api.example.test'
    $script:reportId = '00000000-0000-0000-0000-000000000001'
}

Describe 'New-EPMReport' {
    It 'posts reportId and format and parses a JSON response' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ Content = '[{"a":1},{"a":2}]'; Headers = @{ 'Content-Disposition' = 'attachment; filename=report.json' } } }
        $result = New-EPMReport -SetId 'set-1' -ReportId $script:reportId -Confirm:$false
        $result.SetId | Should -Be 'set-1'
        $result.ReportId | Should -Be $script:reportId
        $result.Format | Should -BeExactly 'JSON'
        $result.FileName | Should -Be 'report.json'
        @($result.Content).Count | Should -Be 2
        $result.PSObject.TypeNames[0] | Should -Be 'psEPM.Report'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'POST' -and $Path -eq 'Sets/set-1/Reports' -and $IncludeResponseHeader -and $Body.reportId -eq $script:reportId -and $Body.format -ceq 'JSON' -and $Body.Count -eq 2
        }
    }

    It 'sends CSV in upper case and keeps CSV content as text' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ Content = "a,b`n1,2"; Headers = @{} } }
        $result = New-EPMReport -SetId 'set-1' -ReportId $script:reportId -Format csv -Confirm:$false
        $result.Format | Should -BeExactly 'CSV'
        $result.Content | Should -BeOfType [string]
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter { $Body.format -ceq 'CSV' }
    }

    It 'writes the response bytes to OutFile' {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes('a,b')
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ Content = $bytes; Headers = @{} } }.GetNewClosure()
        $file = Join-Path $TestDrive 'report.csv'
        $result = New-EPMReport -SetId 'set-1' -ReportId $script:reportId -Format CSV -OutFile $file -Confirm:$false
        $result.Path | Should -Be $file
        [System.IO.File]::ReadAllText($file) | Should -Be 'a,b'
    }

    It 'makes no call with WhatIf' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { throw 'should not be called' }
        $result = New-EPMReport -SetId 'set-1' -ReportId $script:reportId -WhatIf
        $result | Should -BeNullOrEmpty
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 0 -Exactly
    }

    It 'rejects a report ID that is not a GUID without calling the API' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { throw 'should not be called' }
        { New-EPMReport -SetId 'set-1' -ReportId 'not-a-guid' -Confirm:$false } | Should -Throw
        { New-EPMReport -SetId 'set-1' -ReportId $script:reportId -Format XML -Confirm:$false } | Should -Throw
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 0 -Exactly
    }

    It 'takes SetId and ReportId from the pipeline' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ Content = '{}'; Headers = @{} } }
        $result = [pscustomobject]@{ SetId = 'set-2'; ReportId = $script:reportId } | New-EPMReport -Confirm:$false
        $result.SetId | Should -Be 'set-2'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter { $Path -eq 'Sets/set-2/Reports' }
    }

    It 'declares ShouldProcess with medium impact' {
        $meta = New-Object System.Management.Automation.CommandMetadata (Get-Command New-EPMReport)
        $meta.SupportsShouldProcess | Should -BeTrue
        $meta.ConfirmImpact | Should -Be 'Medium'
    }
}
