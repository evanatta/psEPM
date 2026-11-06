BeforeAll {
    Import-Module (Join-Path (Split-Path -Parent $PSScriptRoot) 'psEPM/psEPM.psd1') -Force
}

Describe 'ConvertTo-EPMFilter' {
    It 'quotes string values for EQ and the text operators' {
        ConvertTo-EPMFilter -Property name -Operator EQ -Value 'APITEST-PC' | Should -BeExactly 'name EQ "APITEST-PC"'
        ConvertTo-EPMFilter name NE 'APITEST-PC' | Should -BeExactly 'name NE "APITEST-PC"'
        ConvertTo-EPMFilter PolicyName CONTAINS 'Allow notepad' | Should -BeExactly 'PolicyName CONTAINS "Allow notepad"'
        ConvertTo-EPMFilter PolicyName NOTCONTAINS 'x' | Should -BeExactly 'PolicyName NOTCONTAINS "x"'
        ConvertTo-EPMFilter ip STARTSWITH '10.70' | Should -BeExactly 'ip STARTSWITH "10.70"'
        ConvertTo-EPMFilter ip ENDSWITH '.2' | Should -BeExactly 'ip ENDSWITH ".2"'
        ConvertTo-EPMFilter id EQ '11111111-2222-3333-4444-555555555555' | Should -BeExactly 'id EQ "11111111-2222-3333-4444-555555555555"'
    }

    It 'writes IN and NOTIN lists without one big quoted string' {
        ConvertTo-EPMFilter -Property eventType -Operator IN -Value 'Launch', 'Block' | Should -BeExactly 'eventType IN Launch,Block'
        ConvertTo-EPMFilter id IN 'a1', 'b2' | Should -BeExactly 'id IN a1,b2'
        ConvertTo-EPMFilter inventoryType NOTIN 'InstalledPrograms' | Should -BeExactly 'inventoryType NOTIN InstalledPrograms'
        ConvertTo-EPMFilter computerName IN 'PC 1', 'PC2', 'a,b' | Should -BeExactly 'computerName IN "PC 1",PC2,"a,b"'
    }

    It 'writes dates as unquoted UTC ISO 8601 and numbers and booleans unquoted' {
        $date = New-Object DateTime 2026, 1, 1, 0, 0, 0, ([DateTimeKind]::Utc)
        ConvertTo-EPMFilter arrivalTime GE $date | Should -BeExactly 'arrivalTime GE 2026-01-01T00:00:00Z'
        ConvertTo-EPMFilter arrivalTime LE $date.AddDays(1) | Should -BeExactly 'arrivalTime LE 2026-01-02T00:00:00Z'
        ConvertTo-EPMFilter -Property membersCount -Operator GT -Value 5 | Should -BeExactly 'membersCount GT 5'
        ConvertTo-EPMFilter -Property size -Operator LT -Value 1.5 | Should -BeExactly 'size LT 1.5'
        ConvertTo-EPMFilter -Property IsActive -Operator EQ -Value $true | Should -BeExactly 'IsActive EQ true'
        ConvertTo-EPMFilter -Property versionHash GT '250030060000' | Should -BeExactly 'versionHash GT "250030060000"'
    }

    It 'converts a local date to UTC' {
        $local = New-Object DateTime 2026, 6, 1, 12, 0, 0, ([DateTimeKind]::Local)
        $expected = 'arrivalTime GE ' + $local.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ', [System.Globalization.CultureInfo]::InvariantCulture)
        ConvertTo-EPMFilter arrivalTime GE $local | Should -BeExactly $expected
    }

    It 'joins clauses from hashtables and objects with AND' {
        $clauses = @(
            @{ Property = 'name'; Operator = 'CONTAINS'; Value = 'APITEST' }
            [pscustomobject]@{ Property = 'platform'; Operator = 'in'; Value = @('Windows', 'MacOS') }
            @{ Property = 'connectionStatus'; Operator = 'EQ'; Value = 'Disconnected' }
        )
        $clauses | ConvertTo-EPMFilter | Should -BeExactly 'name CONTAINS "APITEST" AND platform IN Windows,MacOS AND connectionStatus EQ "Disconnected"'
        ConvertTo-EPMFilter -InputObject $clauses | Should -BeExactly 'name CONTAINS "APITEST" AND platform IN Windows,MacOS AND connectionStatus EQ "Disconnected"'
    }

    It 'accepts dotted field names' {
        ConvertTo-EPMFilter features.name EQ 'rem' | Should -BeExactly 'features.name EQ "rem"'
    }

    It 'rejects double quotes and a trailing backslash in values' {
        { ConvertTo-EPMFilter name EQ 'a" OR id EQ "b' } | Should -Throw '*double quote*'
        { ConvertTo-EPMFilter id IN 'a', 'b"' } | Should -Throw '*double quote*'
        { ConvertTo-EPMFilter name EQ 'abc\' } | Should -Throw '*backslash*'
        ConvertTo-EPMFilter userName EQ 'DOMAIN\user' | Should -BeExactly 'userName EQ "DOMAIN\user"'
    }

    It 'rejects blank properties, values and invalid field names' {
        { ConvertTo-EPMFilter -Property ' ' -Operator EQ -Value 'x' } | Should -Throw '*property*'
        { ConvertTo-EPMFilter -Property 'name EQ "x" OR id' -Operator EQ -Value 'x' } | Should -Throw '*not a valid field name*'
        { ConvertTo-EPMFilter -Property name -Operator EQ -Value '' } | Should -Throw '*empty or blank*'
        { ConvertTo-EPMFilter -Property name -Operator EQ -Value '   ' } | Should -Throw '*empty or blank*'
        { ConvertTo-EPMFilter -Property name -Operator IN -Value @() } | Should -Throw '*No value*'
        { ConvertTo-EPMFilter -Property name -Operator IN -Value 'a', '' } | Should -Throw '*empty or blank*'
        { @{ Property = 'name'; Operator = 'EQ' } | ConvertTo-EPMFilter } | Should -Throw '*No value*'
        { @{ Property = 'name'; Operator = 'EQ'; Value = $null } | ConvertTo-EPMFilter } | Should -Throw '*null*'
    }

    It 'rejects unsupported operators and several values for a single-value operator' {
        { ConvertTo-EPMFilter -Property name -Operator LIKE -Value 'x' } | Should -Throw
        { @{ Property = 'name'; Operator = 'BETWEEN'; Value = 'x' } | ConvertTo-EPMFilter } | Should -Throw '*not supported*'
        { @{ Property = 'name'; Operator = ''; Value = 'x' } | ConvertTo-EPMFilter } | Should -Throw '*operator*'
        { ConvertTo-EPMFilter -Property name -Operator EQ -Value 'a', 'b' } | Should -Throw '*IN or NOTIN*'
    }

    It 'rejects empty pipeline input' {
        { @() | ConvertTo-EPMFilter } | Should -Throw '*No filter clauses*'
    }

    It 'is accepted by a Get command as -Filter' {
        $token = ConvertTo-SecureString 'fake-token' -AsPlainText -Force
        New-EPMSession -Token $token -BaseURI 'https://api.example.test'
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ endpoints = @(); filteredCount = 0 } }
        $filter = ConvertTo-EPMFilter -Property name -Operator CONTAINS -Value 'APITEST'
        Get-EPMEndpoint -SetId 'set-1' -Filter $filter | Out-Null
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -ParameterFilter { ($Body | ConvertTo-Json -Compress) -like '*name CONTAINS \"APITEST\"*' -or [string]$Body -like '*name CONTAINS \"APITEST\"*' }
    }
}
