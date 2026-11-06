BeforeAll {
    Import-Module (Join-Path (Split-Path -Parent $PSScriptRoot) 'psEPM/psEPM.psd1') -Force
}

Describe 'Invoke-EPMRestMethod' {
    BeforeAll {
        $token = ConvertTo-SecureString 'fake-token' -AsPlainText -Force
        New-EPMSession -Token $token -BaseURI 'https://api.example.test'
    }

    It 'sends a bearer token and JSON body' {
        Mock -ModuleName psEPM Invoke-RestMethod { [pscustomobject]@{ ok = $true } }
        InModuleScope psEPM {
            Invoke-EPMRestMethod -Method POST -Path 'Sets/s1/Endpoints/search' -Body @{ filter = '' } | Out-Null
        }
        Should -Invoke -ModuleName psEPM Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
            $Uri -eq 'https://api.example.test/API/Sets/s1/Endpoints/search' -and
            $Headers.Authorization -eq 'Bearer fake-token' -and
            $ContentType -eq 'application/json' -and
            $Body -eq '{"filter":""}'
        }
    }

    It 'retries when the API throttles and then succeeds' {
        InModuleScope psEPM {
            $script:calls = 0
            Mock Start-Sleep { }
            Mock Get-EPMErrorDetail { [pscustomobject]@{ StatusCode = 403; ErrorCode = 'EPM050004E'; Message = 'throttled'; Raw = $null } }
            Mock Invoke-RestMethod {
                $script:calls++
                if ($script:calls -lt 3) { throw 'throttled' }
                [pscustomobject]@{ ok = $true }
            }
            (Invoke-EPMRestMethod -Method GET -Path 'Sets').ok | Should -BeTrue
            $script:calls | Should -Be 3
            Should -Invoke Start-Sleep -Times 2 -Exactly
        }
    }

    It 'throws a readable error for other failures' {
        InModuleScope psEPM {
            Mock Get-EPMErrorDetail { [pscustomobject]@{ StatusCode = 404; ErrorCode = 'EPM000004E'; Message = 'not found'; Raw = $null } }
            Mock Invoke-RestMethod { throw 'nope' }
            { Invoke-EPMRestMethod -Method GET -Path 'Sets/x' } | Should -Throw '*HTTP 404 EPM000004E not found*'
        }
    }
}

Describe 'Invoke-EPMPagedRequest' {
    It 'keeps requesting pages until a short page is returned' {
        InModuleScope psEPM {
            Mock Invoke-EPMRestMethod {
                if ($Path -match 'offset=0') { return [pscustomobject]@{ items = @(1, 2) } }
                if ($Path -match 'offset=2') { return [pscustomobject]@{ items = @(3, 4) } }
                [pscustomobject]@{ items = @(5) }
            }
            $result = @(Invoke-EPMPagedRequest -Method GET -Path 'Things' -ItemProperty 'items' -PageSize 2)
            $result.Count | Should -Be 5
            Should -Invoke Invoke-EPMRestMethod -Times 3 -Exactly
        }
    }

    It 'stops at First' {
        InModuleScope psEPM {
            Mock Invoke-EPMRestMethod { [pscustomobject]@{ items = @(1, 2) } }
            @(Invoke-EPMPagedRequest -Method GET -Path 'Things' -ItemProperty 'items' -PageSize 2 -First 3).Count | Should -Be 3
        }
    }
}
