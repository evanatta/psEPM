BeforeAll {
    Import-Module (Join-Path (Split-Path -Parent $PSScriptRoot) 'psEPM/psEPM.psd1') -Force
    $token = ConvertTo-SecureString 'fake-token' -AsPlainText -Force
    New-EPMSession -Token $token -BaseURI 'https://api.example.test'
}

Describe 'ConvertTo-EPMJson' {
    It 'keeps one-item arrays as arrays at any depth' {
        InModuleScope psEPM {
            $json = ConvertTo-EPMJson -InputObject @{ a = @(, @{ b = @('x') }) }
            $json | Should -Be '{"a":[{"b":["x"]}]}'
        }
    }

    It 'writes scalars, nulls, empty arrays and special keys' {
        InModuleScope psEPM {
            $object = [ordered]@{ s = 'q"t'; n = 5; d = 1.5; t = $true; f = $false; z = $null; e = @(); '@type' = 'FileName' }
            ConvertTo-EPMJson -InputObject $object | Should -Be '{"s":"q\"t","n":5,"d":1.5,"t":true,"f":false,"z":null,"e":[],"@type":"FileName"}'
        }
    }

    It 'round-trips an object from ConvertFrom-Json and drops excluded top-level properties' {
        InModuleScope psEPM {
            $object = '{"Id":"p1","Applications":[{"patterns":{"FILE_NAME":{"@type":"FileName"}}}],"SetId":"s"}' | ConvertFrom-Json
            ConvertTo-EPMJson -InputObject $object -ExcludeProperty 'SetId' | Should -Be '{"Id":"p1","Applications":[{"patterns":{"FILE_NAME":{"@type":"FileName"}}}]}'
        }
    }
}

Describe 'New-EPMPolicy' {
    It 'builds the example body with an Applications array and IsActive false' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ Id = 'p-1'; Name = 'Test'; IsActive = $false } }
        $result = New-EPMPolicy -SetId 'set-1' -Name 'Test' -FileName 'notepad.exe' -Description 'Desc'
        $result.PolicyId | Should -Be 'p-1'
        $result.SetId | Should -Be 'set-1'
        $result.PSObject.TypeNames[0] | Should -Be 'psEPM.PolicyDefinition'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter {
            $sent = $Body | ConvertFrom-Json
            $Method -eq 'POST' -and $Path -eq 'Sets/set-1/Policies/Server' -and $Body -is [string] -and
            $Body -match '"Applications":\[\{' -and
            $sent.IsActive -eq $false -and $sent.IsAppliedToAllComputers -eq $true -and $sent.Audit -eq $false -and
            $sent.PolicyType -eq 11 -and $sent.Action -eq 1 -and $sent.Name -eq 'Test' -and $sent.Description -eq 'Desc' -and
            $sent.Applications[0].applicationType -eq 3 -and $sent.Applications[0].displayName -eq 'notepad.exe' -and
            $sent.Applications[0].patterns.FILE_NAME.'@type' -eq 'FileName' -and
            $sent.Applications[0].patterns.FILE_NAME.content -eq 'notepad.exe' -and
            $sent.Applications[0].patterns.FILE_NAME.compareAs -eq 0
        }
    }

    It 'takes SetId from the pipeline and passes overrides' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ Id = 'p-2' } }
        [pscustomobject]@{ SetId = 'set-2' } | New-EPMPolicy -Name 'T' -FileName 'a.exe' -Action 2 -Audit $true
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -ParameterFilter {
            $sent = $Body | ConvertFrom-Json
            $Path -eq 'Sets/set-2/Policies/Server' -and $sent.Action -eq 2 -and $sent.Audit -eq $true -and $sent.IsActive -eq $false
        }
    }

    It 'sends a JSON string policy unchanged' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ Id = 'p-3' } }
        $json = '{"Name":"T","PolicyType":11,"Applications":[{"applicationType":3}]}'
        New-EPMPolicy -SetId 'set-1' -Policy $json
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -ParameterFilter { $Body -eq $json }
    }

    It 'converts a policy object without adding IsActive' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { [pscustomobject]@{ Id = 'p-4' } }
        New-EPMPolicy -SetId 'set-1' -Policy @{ Name = 'T'; PolicyType = 11; Applications = @(@{ applicationType = 3 }) }
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -ParameterFilter {
            $Body -match '"Applications":\[\{"applicationType":3\}\]' -and $Body -notmatch 'IsActive'
        }
    }

    It 'rejects a policy string that is not JSON' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { }
        { New-EPMPolicy -SetId 'set-1' -Policy 'not json' } | Should -Throw '*not valid JSON*'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 0 -Exactly
    }

    It 'does not call the API with -WhatIf' {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { }
        New-EPMPolicy -SetId 'set-1' -Name 'T' -FileName 'a.exe' -WhatIf
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 0 -Exactly
    }
}

Describe 'Set-EPMPolicy' {
    BeforeEach {
        Mock -ModuleName psEPM Invoke-EPMRestMethod {
            [pscustomobject]@{
                CreatedDate = '2026-01-01'
                Policy      = [pscustomobject]@{
                    Id = 'p-1'; Name = 'Old'; PolicyType = 11; Description = 'Old desc'; IsActive = $false; Audit = $false
                    Applications = @([pscustomobject]@{ applicationType = 3; displayName = 'notepad.exe' })
                }
            }
        } -ParameterFilter { $Method -eq 'GET' }
        Mock -ModuleName psEPM Invoke-EPMRestMethod { $Body | ConvertFrom-Json } -ParameterFilter { $Method -eq 'PUT' }
    }

    It 'merges one field into the unwrapped policy and keeps the rest' {
        $result = [pscustomobject]@{ SetId = 'set-1'; PolicyId = 'p-1' } | Set-EPMPolicy -Description 'New desc'
        $result.PolicyId | Should -Be 'p-1'
        $result.SetId | Should -Be 'set-1'
        $result.PSObject.TypeNames[0] | Should -Be 'psEPM.PolicyDefinition'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter { $Method -eq 'GET' -and $Path -eq 'Sets/set-1/Policies/Server/p-1' }
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter {
            if ($Method -ne 'PUT') { return $false }
            $sent = $Body | ConvertFrom-Json
            $Method -eq 'PUT' -and $Path -eq 'Sets/set-1/Policies/Server/p-1' -and
            $Body -notmatch '"Policy":' -and $Body -notmatch 'CreatedDate' -and $Body -match '"Applications":\[\{' -and
            $sent.Id -eq 'p-1' -and $sent.Description -eq 'New desc' -and $sent.Name -eq 'Old' -and $sent.IsActive -eq $false -and $sent.PolicyType -eq 11
        }
    }

    It 'does not send IsActive changes unless asked' {
        Set-EPMPolicy -SetId 'set-1' -PolicyId 'p-1' -Name 'Renamed'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -ParameterFilter {
            if ($Method -ne 'PUT') { return $false }
            $sent = $Body | ConvertFrom-Json
            $Method -eq 'PUT' -and $sent.Name -eq 'Renamed' -and $sent.IsActive -eq $false
        }
    }

    It 'replaces with a full policy object and drops module properties' {
        $detail = [pscustomobject]@{ SetId = 'set-1'; PolicyId = 'p-1'; Policy = [pscustomobject]@{ Id = 'p-1'; Name = 'X'; PolicyType = 11; Applications = @([pscustomobject]@{ applicationType = 3 }) } }
        Set-EPMPolicy -SetId 'set-1' -PolicyId 'p-1' -Policy $detail
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 0 -Exactly -ParameterFilter { $Method -eq 'GET' }
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -ParameterFilter {
            $Method -eq 'PUT' -and $Body -eq '{"Id":"p-1","Name":"X","PolicyType":11,"Applications":[{"applicationType":3}]}'
        }
    }

    It 'does not call the API with -WhatIf' {
        Set-EPMPolicy -SetId 'set-1' -PolicyId 'p-1' -Description 'x' -WhatIf
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 0 -Exactly
    }
}

Describe 'Remove-EPMPolicy' {
    BeforeEach {
        Mock -ModuleName psEPM Invoke-EPMRestMethod { }
    }

    It 'deletes a policy and returns a removal object' {
        $result = Remove-EPMPolicy -SetId 'set-1' -PolicyId 'p-1' -Confirm:$false
        $result.SetId | Should -Be 'set-1'
        $result.PolicyId | Should -Be 'p-1'
        $result.PSObject.TypeNames[0] | Should -Be 'psEPM.PolicyRemoval'
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'DELETE' -and $Path -eq 'Sets/set-1/Policies/Server/p-1' -and -not $PSBoundParameters.ContainsKey('Body')
        }
    }

    It 'deletes each piped policy' {
        @([pscustomobject]@{ SetId = 'set-1'; PolicyId = 'p-1' }, [pscustomobject]@{ SetId = 'set-1'; PolicyId = 'p-2' }) | Remove-EPMPolicy -Confirm:$false
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 2 -Exactly
    }

    It 'does not call the API with -WhatIf' {
        Remove-EPMPolicy -SetId 'set-1' -PolicyId 'p-1', 'p-2' -WhatIf
        Should -Invoke -ModuleName psEPM Invoke-EPMRestMethod -Times 0 -Exactly
    }

    It 'has a high confirm impact' {
        $meta = New-Object System.Management.Automation.CommandMetadata (Get-Command Remove-EPMPolicy)
        $meta.ConfirmImpact | Should -Be 'High'
    }
}
