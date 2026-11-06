BeforeAll {
    Import-Module (Join-Path (Split-Path -Parent $PSScriptRoot) 'psEPM/psEPM.psd1') -Force
    $token = ConvertTo-SecureString 'fake-token' -AsPlainText -Force
    New-EPMSession -Token $token -BaseURI 'https://api.example.test'
}

Describe 'Export-EPMPolicy' {
    It 'maps group types to ServerPolicyGroupType' -TestCases @(
        @{ GroupType = 'Computer'; Value = 0 },
        @{ GroupType = 'User'; Value = 1 },
        @{ GroupType = 'All'; Value = 3 }
    ) {
        param($GroupType, $Value)
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ Content = '{"Policies":[],"AppGroups":[]}'; Headers = @{} } }
        Export-EPMPolicy -SetId 'set-1' -GroupType $GroupType | Out-Null
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'POST' -and $Path -eq 'Sets/set-1/Policies/Server/Export' -and $Body.ServerPolicyGroupType -eq $Value -and $IncludeResponseHeader
        }
    }

    It 'defaults to All, parses byte content, strips a BOM and reads the file name' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod {
            $bytes = [byte[]](@(0xEF, 0xBB, 0xBF) + [System.Text.Encoding]::UTF8.GetBytes('{"Policies":[{"Name":"A"}],"AppGroups":[]}'))
            [pscustomobject]@{ Content = $bytes; Headers = @{ 'Content-Disposition' = @('attachment; filename=Policies-01-Jan-26_10-00-00.epmp') } }
        }
        $result = [pscustomobject]@{ SetId = 'set-2' } | Export-EPMPolicy
        $result.SetId | Should -Be 'set-2'
        $result.GroupType | Should -Be 'All'
        $result.FileName | Should -Be 'Policies-01-Jan-26_10-00-00.epmp'
        $result.Export.Policies[0].Name | Should -Be 'A'
        $result.PSObject.TypeNames[0] | Should -Be 'psEPM.PolicyExport'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -ParameterFilter { $Path -eq 'Sets/set-2/Policies/Server/Export' -and $Body.ServerPolicyGroupType -eq 3 }
    }

    It 'writes the raw content to OutFile' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ Content = [System.Text.Encoding]::UTF8.GetBytes('{"Policies":[]}'); Headers = @{} } }
        $file = Join-Path $TestDrive 'out.epmp'
        $result = Export-EPMPolicy -SetId 'set-1' -GroupType Computer -OutFile $file
        $result.Path | Should -Be $file
        Get-Content -Path $file -Raw | Should -Be '{"Policies":[]}'
    }

    It 'rejects other group types' {
        { Export-EPMPolicy -SetId 'set-1' -GroupType Empty } | Should -Throw
    }
}

Describe 'Get-EPMApplicationGroup' {
    It 'searches with an empty body and adds ApplicationGroupId' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ Policies = @([pscustomobject]@{ PolicyId = 'a-1'; PolicyName = 'Lab' }) } }
        $result = Get-EPMApplicationGroup -SetId 'set-1'
        $result.ApplicationGroupId | Should -Be 'a-1'
        $result.SetId | Should -Be 'set-1'
        $result.PSObject.TypeNames[0] | Should -Be 'psEPM.ApplicationGroup'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -ParameterFilter {
            $Method -eq 'POST' -and $Path -like 'Sets/set-1/Policies/ApplicationGroups/Search?*' -and $Body.Count -eq 0
        }
    }

    It 'filters by name' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ Policies = @() } }
        Get-EPMApplicationGroup -SetId 'set-1' -Name 'Lab'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -ParameterFilter { $Body.filter -eq 'PolicyName CONTAINS "Lab"' }
    }

    It 'gets details from a piped search row using PolicyId' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ Policy = [pscustomobject]@{ Id = 'a-1'; PolicyType = 14 } } }
        $detail = [pscustomobject]@{ SetId = 'set-1'; PolicyId = 'a-1' } | Get-EPMApplicationGroup
        $detail.ApplicationGroupId | Should -Be 'a-1'
        $detail.PolicyId | Should -Be 'a-1'
        $detail.PSObject.TypeNames[0] | Should -Be 'psEPM.ApplicationGroupDetail'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -ParameterFilter { $Method -eq 'GET' -and $Path -eq 'Sets/set-1/Policies/ApplicationGroups/a-1' }
    }
}

Describe 'New-EPMApplicationGroup' {
    It 'builds the example body with PolicyType 14 and an Applications array' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ Id = 'a-1'; Name = 'Lab'; PolicyType = 14 } }
        $result = New-EPMApplicationGroup -SetId 'set-1' -Name 'Lab' -FileName 'notepad.exe' -Description 'Desc'
        $result.ApplicationGroupId | Should -Be 'a-1'
        $result.SetId | Should -Be 'set-1'
        $result.PSObject.TypeNames[0] | Should -Be 'psEPM.ApplicationGroupDefinition'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter {
            $sent = $Body | ConvertFrom-Json
            $Method -eq 'POST' -and $Path -eq 'Sets/set-1/Policies/ApplicationGroups' -and $Body -is [string] -and
            $Body -match '"Applications":\[\{' -and $Body -notmatch 'IsActive' -and $Body -notmatch '"Action"' -and
            $sent.PolicyType -eq 14 -and $sent.Name -eq 'Lab' -and $sent.Description -eq 'Desc' -and
            $sent.Applications[0].applicationType -eq 3 -and
            $sent.Applications[0].patterns.FILE_NAME.'@type' -eq 'FileName' -and
            $sent.Applications[0].patterns.FILE_NAME.content -eq 'notepad.exe'
        }
    }

    It 'takes SetId from the pipeline and sends a JSON string unchanged' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ Id = 'a-2' } }
        $json = '{"Name":"X","PolicyType":14,"Applications":[{"applicationType":3}]}'
        [pscustomobject]@{ SetId = 'set-2' } | New-EPMApplicationGroup -Policy $json
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -ParameterFilter { $Path -eq 'Sets/set-2/Policies/ApplicationGroups' -and $Body -eq $json }
    }

    It 'does not call the API with -WhatIf' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { }
        New-EPMApplicationGroup -SetId 'set-1' -Name 'Lab' -FileName 'a.exe' -WhatIf
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 0 -Exactly
    }
}

Describe 'Set-EPMApplicationGroup' {
    BeforeEach {
        Mock -ModuleName psEPM Invoke-EPMRestMethod {
            [pscustomobject]@{
                CreatedDate = '2026-01-01'
                Policy      = [pscustomobject]@{
                    Id = 'a-1'; Name = 'Lab'; PolicyType = 14; Description = 'Old'
                    Applications = @([pscustomobject]@{ id = 'app-1'; applicationType = 3; displayName = 'notepad.exe' })
                }
            }
        } -ParameterFilter { $Method -eq 'GET' }
        Mock -ModuleName psEPM Invoke-EPMRestMethod { $Body | ConvertFrom-Json } -ParameterFilter { $Method -eq 'PUT' }
    }

    It 'merges the description into the unwrapped definition' {
        $result = [pscustomobject]@{ SetId = 'set-1'; PolicyId = 'a-1' } | Set-EPMApplicationGroup -Description 'New'
        $result.ApplicationGroupId | Should -Be 'a-1'
        $result.SetId | Should -Be 'set-1'
        $result.PSObject.TypeNames[0] | Should -Be 'psEPM.ApplicationGroupDefinition'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter { $Method -eq 'GET' -and $Path -eq 'Sets/set-1/Policies/ApplicationGroups/a-1' }
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter {
            if ($Method -ne 'PUT') { return $false }
            $sent = $Body | ConvertFrom-Json
            $Path -eq 'Sets/set-1/Policies/ApplicationGroups/a-1' -and $Body -notmatch '"Policy":' -and $Body -match '"Applications":\[\{' -and
            $sent.Description -eq 'New' -and $sent.Name -eq 'Lab' -and $sent.PolicyType -eq 14 -and $sent.Id -eq 'a-1' -and $sent.Applications[0].id -eq 'app-1'
        }
    }

    It 'replaces with a detail object and unwraps Policy' {
        $detail = [pscustomobject]@{ SetId = 'set-1'; ApplicationGroupId = 'a-1'; PolicyId = 'a-1'; Policy = [pscustomobject]@{ Id = 'a-1'; Name = 'X'; PolicyType = 14; Applications = @([pscustomobject]@{ applicationType = 3 }) } }
        $detail | Set-EPMApplicationGroup -Policy $detail
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 0 -Exactly -ParameterFilter { $Method -eq 'GET' }
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -ParameterFilter {
            $Method -eq 'PUT' -and $Body -eq '{"Id":"a-1","Name":"X","PolicyType":14,"Applications":[{"applicationType":3}]}'
        }
    }

    It 'does not call the API with -WhatIf' {
        Set-EPMApplicationGroup -SetId 'set-1' -ApplicationGroupId 'a-1' -Description 'x' -WhatIf
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 0 -Exactly
    }
}

Describe 'Remove-EPMApplicationGroup' {
    BeforeEach {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { }
    }

    It 'deletes without /Server in the path and returns a removal object' {
        $result = Remove-EPMApplicationGroup -SetId 'set-1' -ApplicationGroupId 'a-1' -Confirm:$false
        $result.SetId | Should -Be 'set-1'
        $result.ApplicationGroupId | Should -Be 'a-1'
        $result.PSObject.TypeNames[0] | Should -Be 'psEPM.ApplicationGroupRemoval'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'DELETE' -and $Path -eq 'Sets/set-1/Policies/ApplicationGroups/a-1' -and -not $PSBoundParameters.ContainsKey('Body')
        }
    }

    It 'deletes each piped search row' {
        @([pscustomobject]@{ SetId = 'set-1'; PolicyId = 'a-1' }, [pscustomobject]@{ SetId = 'set-1'; PolicyId = 'a-2' }) | Remove-EPMApplicationGroup -Confirm:$false
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 2 -Exactly
    }

    It 'does not call the API with -WhatIf' {
        Remove-EPMApplicationGroup -SetId 'set-1' -ApplicationGroupId 'a-1' -WhatIf
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 0 -Exactly
    }

    It 'has a high confirm impact' {
        $meta = New-Object System.Management.Automation.CommandMetadata (Get-Command Remove-EPMApplicationGroup)
        $meta.ConfirmImpact | Should -Be 'High'
    }
}
