BeforeAll {
    Import-Module (Join-Path (Split-Path -Parent $PSScriptRoot) 'psEPM/psEPM.psd1') -Force
    $token = ConvertTo-SecureString 'fake-token' -AsPlainText -Force
    New-EPMSession -Token $token -BaseURI 'https://api.example.test'
    $script:EndpointGuid = '11111111-2222-3333-4444-555555555555'
    $script:ZeroGuid = '00000000-0000-0000-0000-000000000000'
}

Describe 'New-EPMAgentConfiguration' {
    BeforeEach {
        Mock -ModuleName psEPM Invoke-EPMRestMethod -ParameterFilter { $Method -eq 'GET' } {
            [pscustomobject]@{
                CreatedDate = 'c'; Order = 1; OsType = 1
                Policy      = [pscustomobject]@{
                    Id = 'set-1'; Name = 'General configuration'; PolicyType = 44; Action = 10; Description = $null
                    IsActive = $false; IsAppliedToAllComputers = $true; Executors = @(); IncludeComputerGroups = @()
                    AgentBehavior = [pscustomobject]@{ Mode = 1 }; Accounts = @([pscustomobject]@{ Name = 'a' })
                }
            }
        }
        Mock -ModuleName psEPM Invoke-EPMRestMethod -ParameterFilter { $Method -eq 'POST' } {
            [pscustomobject]@{ Id = '11111111-2222-3333-4444-555555555555'; Name = 'APITEST_AgentConfig'; PolicyType = 44 }
        }
    }

    It 'reads the General configuration by default and posts the definition with one computer executor' {
        $result = New-EPMAgentConfiguration -SetId 'set-1' -Name 'APITEST_AgentConfig' -EndpointId $script:EndpointGuid -Confirm:$false
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter { $Method -eq 'GET' -and $Path -eq 'Sets/set-1/Policies/AgentConfiguration/set-1' }
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter {
            if ($Method -ne 'POST') { return $false }
            $sent = $Body | ConvertFrom-Json
            $Method -eq 'POST' -and $Path -eq 'Sets/set-1/Policies/AgentConfiguration' -and
            $sent.Id -eq '00000000-0000-0000-0000-000000000000' -and $sent.Name -eq 'APITEST_AgentConfig' -and
            $sent.IsAppliedToAllComputers -eq $false -and $sent.PolicyType -eq 44 -and $sent.AgentBehavior.Mode -eq 1 -and
            $Body.Contains('"Executors":[{"Id":"11111111-2222-3333-4444-555555555555","IsIncluded":true,"ExecutorType":1}]') -and
            $Body.Contains('"Accounts":[{"Name":"a"}]') -and $Body -notlike '*CreatedDate*' -and $Body -notlike '*"Policy":*'
        }
        $result.SetId | Should -Be 'set-1'
        $result.AgentConfigurationId | Should -Be $script:EndpointGuid
        $result.PolicyId | Should -Be $script:EndpointGuid
        $result.PSObject.TypeNames[0] | Should -Be 'psEPM.AgentConfigurationDefinition'
    }

    It 'uses a source configuration and sets Description only when given' {
        New-EPMAgentConfiguration -SetId 'set-1' -Name 'APITEST_AgentConfig' -EndpointId $script:EndpointGuid -SourceAgentConfigurationId 'src-1' -Description 'Lab' -Confirm:$false | Out-Null
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter { $Method -eq 'GET' -and $Path -eq 'Sets/set-1/Policies/AgentConfiguration/src-1' }
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter { $Method -eq 'POST' -and ($Body | ConvertFrom-Json).Description -eq 'Lab' }
    }

    It 'posts a -Policy object with the wrapper removed and the ID cleared' {
        $detail = [pscustomobject]@{ Order = 1; Policy = [pscustomobject]@{ Id = 'set-1'; Name = 'APITEST_AgentConfig'; PolicyType = 44; Executors = @([pscustomobject]@{ Id = 'e'; IsIncluded = $true; ExecutorType = 1 }) }; SetId = 'set-1'; PolicyId = 'set-1'; AgentConfigurationId = 'set-1' }
        New-EPMAgentConfiguration -SetId 'set-1' -Policy $detail -Confirm:$false | Out-Null
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 0 -Exactly -ParameterFilter { $Method -eq 'GET' }
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'POST' -and $Body -ceq '{"Id":"00000000-0000-0000-0000-000000000000","Name":"APITEST_AgentConfig","PolicyType":44,"Executors":[{"Id":"e","IsIncluded":true,"ExecutorType":1}]}'
        }
    }

    It 'accepts a JSON string and drops module properties from a default template' {
        New-EPMAgentConfiguration -SetId 'set-1' -Policy '{"Id":"x","Name":"APITEST_AgentConfig","PolicyType":44,"SetId":"set-1","AgentConfigurationId":"x","Executors":[{"Id":"e","IsIncluded":true,"ExecutorType":1}]}' -Confirm:$false | Out-Null
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'POST' -and $Body -ceq '{"Id":"00000000-0000-0000-0000-000000000000","Name":"APITEST_AgentConfig","PolicyType":44,"Executors":[{"Id":"e","IsIncluded":true,"ExecutorType":1}]}'
        }
    }

    It 'rejects missing, blank, or invalid input without calling the API' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { throw 'should not be called' }
        { New-EPMAgentConfiguration -SetId 'set-1' -Name '   ' -EndpointId $script:EndpointGuid -Confirm:$false } | Should -Throw '*blank*'
        { New-EPMAgentConfiguration -SetId 'set-1' -Name '' -EndpointId $script:EndpointGuid -Confirm:$false } | Should -Throw
        { New-EPMAgentConfiguration -SetId 'set-1' -Name 'APITEST_AgentConfig' -EndpointId 'PC01' -Confirm:$false } | Should -Throw
        { New-EPMAgentConfiguration -SetId 'set-1' -Name 'APITEST_AgentConfig' -EndpointId $script:ZeroGuid -Confirm:$false } | Should -Throw '*existing computer*'
        { New-EPMAgentConfiguration -SetId 'set-1' -Policy '{not json' -Confirm:$false } | Should -Throw '*not valid JSON*'
        { New-EPMAgentConfiguration -SetId 'set-1' -Policy '[1,2]' -Confirm:$false } | Should -Throw '*single*'
        (Get-Command New-EPMAgentConfiguration).Parameters['EndpointId'].Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -Contain $true
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 0 -Exactly
    }

    It 'makes no call, including the source read, with WhatIf' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { throw 'should not be called' }
        New-EPMAgentConfiguration -SetId 'set-1' -Name 'APITEST_AgentConfig' -EndpointId $script:EndpointGuid -WhatIf | Should -BeNullOrEmpty
        New-EPMAgentConfiguration -SetId 'set-1' -Policy '{"Name":"APITEST_AgentConfig"}' -WhatIf | Should -BeNullOrEmpty
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 0 -Exactly
    }

    It 'declares ShouldProcess with medium impact and takes SetId from the pipeline' {
        $meta = New-Object System.Management.Automation.CommandMetadata (Get-Command New-EPMAgentConfiguration)
        $meta.SupportsShouldProcess | Should -BeTrue
        $meta.ConfirmImpact | Should -Be 'Medium'
        [pscustomobject]@{ SetId = 'set-2' } | New-EPMAgentConfiguration -Name 'APITEST_AgentConfig' -EndpointId $script:EndpointGuid -Confirm:$false | Out-Null
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter { $Method -eq 'POST' -and $Path -eq 'Sets/set-2/Policies/AgentConfiguration' }
    }

    It 'surfaces an API error' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod -ParameterFilter { $Method -eq 'POST' } { throw 'EPM API POST Sets/set-1/Policies/AgentConfiguration failed. HTTP 400' }
        { New-EPMAgentConfiguration -SetId 'set-1' -Name 'APITEST_AgentConfig' -EndpointId $script:EndpointGuid -Confirm:$false } | Should -Throw '*HTTP 400*'
    }
}

Describe 'Set-EPMAgentConfiguration' {
    BeforeEach {
        Mock -ModuleName psEPM Invoke-EPMRestMethod -ParameterFilter { $Method -eq 'GET' } {
            [pscustomobject]@{
                CreatedDate = 'c'; ModifiedDate = 'm'; Order = 1; OsType = 1
                Policy      = [pscustomobject]@{
                    Id = 'cfg-1'; Name = 'APITEST_AgentConfig'; PolicyType = 44; Action = 10; Description = 'old'
                    IsAppliedToAllComputers = $false; Executors = @([pscustomobject]@{ Id = 'cfg-1'; IsIncluded = $true; ExecutorType = 1 })
                    Accounts = @([pscustomobject]@{ Name = 'a' }); AgentBehavior = [pscustomobject]@{ Mode = 1 }
                }
            }
        }
        Mock -ModuleName psEPM Invoke-EPMRestMethod -ParameterFilter { $Method -eq 'PUT' } {
            [pscustomobject]@{ Id = 'cfg-1'; Name = 'APITEST_AgentConfig'; PolicyType = 44 }
        }
    }

    It 'reads, merges Description, and puts the full bare definition back' {
        $result = Set-EPMAgentConfiguration -SetId 'set-1' -AgentConfigurationId 'cfg-1' -Description 'new' -Confirm:$false
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter { $Method -eq 'GET' -and $Path -eq 'Sets/set-1/Policies/AgentConfiguration/cfg-1' }
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter {
            if ($Method -ne 'PUT') { return $false }
            $sent = $Body | ConvertFrom-Json
            $Method -eq 'PUT' -and $Path -eq 'Sets/set-1/Policies/AgentConfiguration/cfg-1' -and
            $sent.Description -eq 'new' -and $sent.Name -eq 'APITEST_AgentConfig' -and $sent.AgentBehavior.Mode -eq 1 -and
            $Body.Contains('"Executors":[{"Id":"cfg-1","IsIncluded":true,"ExecutorType":1}]') -and $Body.Contains('"Accounts":[{"Name":"a"}]') -and
            $Body -notlike '*"Policy":*' -and $Body -notlike '*ModifiedDate*'
        }
        $result.SetId | Should -Be 'set-1'
        $result.AgentConfigurationId | Should -Be 'cfg-1'
        $result.PSObject.TypeNames[0] | Should -Be 'psEPM.AgentConfigurationDefinition'
    }

    It 'merges Name and allows an empty Description' {
        Set-EPMAgentConfiguration -SetId 'set-1' -AgentConfigurationId 'cfg-1' -Name 'APITEST_Renamed' -Description '' -Confirm:$false | Out-Null
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter { $Method -eq 'PUT' -and ($Body | ConvertFrom-Json).Name -eq 'APITEST_Renamed' -and ($Body | ConvertFrom-Json).Description -eq '' }
    }

    It 'replaces with -Policy without a read, and the path ID wins over the body ID' {
        $policy = [pscustomobject]@{ Policy = [pscustomobject]@{ Id = 'other'; Name = 'APITEST_AgentConfig'; PolicyType = 44 } }
        Set-EPMAgentConfiguration -SetId 'set-1' -AgentConfigurationId 'cfg-1' -Policy $policy -Confirm:$false | Out-Null
        Set-EPMAgentConfiguration -SetId 'set-1' -AgentConfigurationId 'cfg-1' -Policy '{"Id":"other","Name":"APITEST_AgentConfig","PolicyType":44,"SetId":"s"}' -Confirm:$false | Out-Null
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 0 -Exactly -ParameterFilter { $Method -eq 'GET' }
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 2 -Exactly -ParameterFilter { $Method -eq 'PUT' -and $Body -ceq '{"Id":"cfg-1","Name":"APITEST_AgentConfig","PolicyType":44}' }
    }

    It 'merge mode also sends the path ID' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod -ParameterFilter { $Method -eq 'GET' } { [pscustomobject]@{ Policy = [pscustomobject]@{ Id = 'other'; Name = 'n'; PolicyType = 44 } } }
        Set-EPMAgentConfiguration -SetId 'set-1' -AgentConfigurationId 'cfg-1' -Description 'd' -Confirm:$false | Out-Null
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter { $Method -eq 'PUT' -and ($Body | ConvertFrom-Json).Id -eq 'cfg-1' }
    }

    It 'rejects no change, a blank name, or invalid JSON without calling the API' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { throw 'should not be called' }
        { Set-EPMAgentConfiguration -SetId 'set-1' -AgentConfigurationId 'cfg-1' -Confirm:$false } | Should -Throw '*Specify*'
        { Set-EPMAgentConfiguration -SetId 'set-1' -AgentConfigurationId 'cfg-1' -Name '  ' -Confirm:$false } | Should -Throw '*blank*'
        { Set-EPMAgentConfiguration -SetId 'set-1' -AgentConfigurationId '' -Description 'd' -Confirm:$false } | Should -Throw
        { Set-EPMAgentConfiguration -SetId 'set-1' -AgentConfigurationId 'cfg-1' -Policy '{bad' -Confirm:$false } | Should -Throw '*not valid JSON*'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 0 -Exactly
    }

    It 'makes no call, including the read, with WhatIf' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { throw 'should not be called' }
        Set-EPMAgentConfiguration -SetId 'set-1' -AgentConfigurationId 'cfg-1' -Description 'd' -WhatIf | Should -BeNullOrEmpty
        Set-EPMAgentConfiguration -SetId 'set-1' -AgentConfigurationId 'cfg-1' -Policy '{"Name":"n"}' -WhatIf | Should -BeNullOrEmpty
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 0 -Exactly
    }

    It 'takes SetId and PolicyId from search rows and declares medium impact' {
        [pscustomobject]@{ SetId = 'set-2'; PolicyId = 'cfg-9'; PolicyName = 'APITEST_AgentConfig' } | Set-EPMAgentConfiguration -Description 'd' -Confirm:$false | Out-Null
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter { $Method -eq 'PUT' -and $Path -eq 'Sets/set-2/Policies/AgentConfiguration/cfg-9' }
        $meta = New-Object System.Management.Automation.CommandMetadata (Get-Command Set-EPMAgentConfiguration)
        $meta.SupportsShouldProcess | Should -BeTrue
        $meta.ConfirmImpact | Should -Be 'Medium'
    }

    It 'stops before the PUT when the read of an unknown ID fails' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod -ParameterFilter { $Method -eq 'GET' } { throw 'EPM API GET Sets/set-1/Policies/AgentConfiguration/x failed. HTTP 404' }
        { Set-EPMAgentConfiguration -SetId 'set-1' -AgentConfigurationId 'x' -Description 'd' -Confirm:$false } | Should -Throw '*HTTP 404*'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 0 -Exactly -ParameterFilter { $Method -eq 'PUT' }
    }
}

Describe 'Remove-EPMAgentConfiguration' {
    It 'deletes each ID once and returns a removal object' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { $null }
        $result = @(Remove-EPMAgentConfiguration -SetId 'set-1' -AgentConfigurationId 'cfg-1', 'cfg-2' -Confirm:$false)
        $result.Count | Should -Be 2
        $result[0].SetId | Should -Be 'set-1'
        $result[0].AgentConfigurationId | Should -Be 'cfg-1'
        $result[0].PSObject.TypeNames[0] | Should -Be 'psEPM.AgentConfigurationRemoval'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter { $Method -eq 'DELETE' -and $Path -eq 'Sets/set-1/Policies/AgentConfiguration/cfg-1' -and $null -eq $Body }
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 2 -Exactly
    }

    It 'takes SetId, PolicyId and PolicyName from search rows' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { $null }
        $result = [pscustomobject]@{ SetId = 'set-2'; PolicyId = 'cfg-9'; PolicyName = 'APITEST_AgentConfig' } | Remove-EPMAgentConfiguration -Confirm:$false
        $result.Name | Should -Be 'APITEST_AgentConfig'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter { $Method -eq 'DELETE' -and $Path -eq 'Sets/set-2/Policies/AgentConfiguration/cfg-9' }
    }

    It 'refuses the General configuration and blank IDs without calling the API' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { throw 'should not be called' }
        $errors = $null
        Remove-EPMAgentConfiguration -SetId 'set-1' -AgentConfigurationId 'set-1' -Confirm:$false -ErrorVariable errors -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        $errors[0].FullyQualifiedErrorId | Should -BeLike 'EPMGeneralConfiguration*'
        { Remove-EPMAgentConfiguration -SetId 'set-1' -AgentConfigurationId '' -Confirm:$false } | Should -Throw
        Remove-EPMAgentConfiguration -SetId 'set-1' -AgentConfigurationId 'a', ' ' -WhatIf -ErrorAction SilentlyContinue | Out-Null
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 0 -Exactly
    }

    It 'makes no call with WhatIf and declares high impact' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { throw 'should not be called' }
        Remove-EPMAgentConfiguration -SetId 'set-1' -AgentConfigurationId 'cfg-1' -WhatIf | Should -BeNullOrEmpty
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 0 -Exactly
        $meta = New-Object System.Management.Automation.CommandMetadata (Get-Command Remove-EPMAgentConfiguration)
        $meta.SupportsShouldProcess | Should -BeTrue
        $meta.ConfirmImpact | Should -Be 'High'
    }

    It 'surfaces a 404 for an unknown ID and does not retry' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { throw 'EPM API DELETE Sets/set-1/Policies/AgentConfiguration/x failed. HTTP 404 EPM060001E' }
        { Remove-EPMAgentConfiguration -SetId 'set-1' -AgentConfigurationId 'x' -Confirm:$false } | Should -Throw '*HTTP 404*'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly
    }
}
