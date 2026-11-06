BeforeAll {
    Import-Module (Join-Path (Split-Path -Parent $PSScriptRoot) 'psEPM/psEPM.psd1') -Force

    function script:New-TestJwt {
        param([double]$SecondsFromNow, [switch]$NoExp)
        $encode = {
            param([string]$Text)
            [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($Text)).TrimEnd('=').Replace('+', '-').Replace('/', '_')
        }
        $exp = [Math]::Floor(([datetime]::UtcNow - (New-Object DateTime 1970, 1, 1, 0, 0, 0, ([DateTimeKind]::Utc))).TotalSeconds + $SecondsFromNow)
        $payload = '{"sub":"svc","exp":' + $exp + ',"pad":"' + ('x' * ([int]$exp % 3)) + '"}'
        if ($NoExp) { $payload = '{"sub":"svc"}' }
        (& $encode '{"alg":"RS256","typ":"JWT"}') + '.' + (& $encode $payload) + '.c2ln'
    }
}

Describe 'Get-EPMTokenExpiry' {
    It 'reads exp from a JWT payload with missing padding' {
        $jwt = New-TestJwt -SecondsFromNow 3600
        InModuleScope psEPM -Parameters @{ Jwt = $jwt } {
            param($Jwt)
            $expiry = Get-EPMTokenExpiry -Token $Jwt
            $expiry.Kind | Should -Be 'Utc'
            ($expiry - [datetime]::UtcNow).TotalSeconds | Should -BeGreaterThan 3500
        }
    }

    It 'returns nothing for a token that is not a JWT or has no exp' {
        $noExp = New-TestJwt -NoExp
        InModuleScope psEPM -Parameters @{ NoExp = $noExp } {
            param($NoExp)
            Get-EPMTokenExpiry -Token 'fake-token' | Should -BeNullOrEmpty
            Get-EPMTokenExpiry -Token 'a.b' | Should -BeNullOrEmpty
            Get-EPMTokenExpiry -Token 'a.!!!.c' | Should -BeNullOrEmpty
            Get-EPMTokenExpiry -Token '' | Should -BeNullOrEmpty
            Get-EPMTokenExpiry -Token $NoExp | Should -BeNullOrEmpty
        }
    }
}

Describe 'Token expiry check' {
    BeforeEach {
        Close-EPMSession
        Mock -ModuleName psEPM Invoke-RestMethod -ParameterFilter { $Uri -like 'https://api.example.test/*' } { [pscustomobject]@{ Sets = @() } }
    }

    It 'skips the check for a token that is not a JWT' {
        $token = ConvertTo-SecureString 'fake-token' -AsPlainText -Force
        New-EPMSession -Token $token -BaseURI 'https://api.example.test'
        Mock -ModuleName psEPM Get-EPMIdentityToken { throw 'should not renew' }
        { Get-EPMSet } | Should -Not -Throw
        (Get-EPMSession).TokenExpiresAt | Should -BeNullOrEmpty
        Should -Invoke -ModuleName psEPM Get-EPMIdentityToken -Times 0 -Exactly
    }

    It 'does not renew a JWT that is not near expiry and shows TokenExpiresAt' {
        $jwt = New-TestJwt -SecondsFromNow 3600
        New-EPMSession -Token (ConvertTo-SecureString $jwt -AsPlainText -Force) -BaseURI 'https://api.example.test'
        Mock -ModuleName psEPM Get-EPMIdentityToken { throw 'should not renew' }
        Get-EPMSet | Out-Null
        Should -Invoke -ModuleName psEPM Get-EPMIdentityToken -Times 0 -Exactly
        Should -Invoke -ModuleName psEPM Invoke-RestMethod -Times 1 -Exactly -ParameterFilter { $Headers.Authorization -eq ('Bearer ' + $jwt) }
        $expires = (Get-EPMSession).TokenExpiresAt
        $expires | Should -BeOfType [datetime]
        $expires.Kind | Should -Be 'Local'
    }

    It 'throws for an expired JWT on a -Token session without calling the API' {
        $jwt = New-TestJwt -SecondsFromNow -10
        New-EPMSession -Token (ConvertTo-SecureString $jwt -AsPlainText -Force) -BaseURI 'https://api.example.test'
        Mock -ModuleName psEPM Get-EPMIdentityToken { throw 'should not renew' }
        { Get-EPMSet } | Should -Throw '*Run New-EPMSession again*'
        Should -Invoke -ModuleName psEPM Invoke-RestMethod -Times 0 -Exactly
        Should -Invoke -ModuleName psEPM Get-EPMIdentityToken -Times 0 -Exactly
    }

    It 'throws for a -Token JWT inside the 60 second window' {
        $jwt = New-TestJwt -SecondsFromNow 30
        New-EPMSession -Token (ConvertTo-SecureString $jwt -AsPlainText -Force) -BaseURI 'https://api.example.test'
        { Get-EPMSet } | Should -Throw '*cannot renew*'
        Should -Invoke -ModuleName psEPM Invoke-RestMethod -Times 0 -Exactly
    }

    Context 'client credentials' {
        BeforeEach {
            $secret = ConvertTo-SecureString 'fake-secret' -AsPlainText -Force
            $script:cred = New-Object System.Management.Automation.PSCredential('svc@example.test', $secret)
            $script:soon = New-TestJwt -SecondsFromNow 30
            $script:fresh = New-TestJwt -SecondsFromNow 3600
            $script:expired = New-TestJwt -SecondsFromNow -600
        }

        It 'renews a token inside the 60 second window with the stored credential and uses the new token' {
            $first = $script:soon
            Mock -ModuleName psEPM Invoke-RestMethod -ParameterFilter { $Uri -like 'https://abc1234.id.cyberark.cloud/*' } { [pscustomobject]@{ access_token = $first } }
            New-EPMSession -TenantId 'abc1234' -WebAppId 'webapp' -Credential $script:cred -BaseURI 'https://api.example.test'
            $second = $script:fresh
            Mock -ModuleName psEPM Invoke-RestMethod -ParameterFilter { $Uri -like 'https://abc1234.id.cyberark.cloud/*' } { [pscustomobject]@{ access_token = $second } }
            Get-EPMSet | Out-Null
            $expected = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('svc@example.test:fake-secret'))
            Should -Invoke -ModuleName psEPM Invoke-RestMethod -Times 2 -Exactly -ParameterFilter {
                $Uri -eq 'https://abc1234.id.cyberark.cloud/oauth2/token/webapp' -and $Method -eq 'POST' -and
                $Headers.Authorization -eq $expected -and $Body -eq 'grant_type=client_credentials' -and $ContentType -eq 'application/x-www-form-urlencoded'
            }
            Should -Invoke -ModuleName psEPM Invoke-RestMethod -Times 1 -Exactly -ParameterFilter { $Uri -like 'https://api.example.test/*' -and $Headers.Authorization -eq ('Bearer ' + $second) }
            (Get-EPMSession -IncludeToken).Token | Should -Be $script:fresh
            ((Get-EPMSession).TokenExpiresAt - (Get-Date)).TotalSeconds | Should -BeGreaterThan 3500
        }

        It 'renews an expired token' {
            InModuleScope psEPM -Parameters @{ Expired = $script:expired; Fresh = $script:fresh; Cred = $script:cred } {
                param($Expired, $Fresh, $Cred)
                $script:EPMSession = New-EPMSessionObject -BaseURI 'https://api.example.test' -Token $Expired -AuthMethod 'IdentityClientCredentials' -User $Cred.UserName -TenantId 'abc1234' -WebAppId 'webapp' -Credential $Cred
                Mock Get-EPMIdentityToken { $Fresh }
                Assert-EPMSession
                Should -Invoke Get-EPMIdentityToken -Times 1 -Exactly -ParameterFilter { $TenantId -eq 'abc1234' -and $WebAppId -eq 'webapp' -and $Credential.UserName -eq 'svc@example.test' }
                $script:EPMSession.Token | Should -Be $Fresh
            }
        }

        It 'throws without calling the API when a renewal fails' {
            InModuleScope psEPM -Parameters @{ Expired = $script:expired; Cred = $script:cred } {
                param($Expired, $Cred)
                $script:EPMSession = New-EPMSessionObject -BaseURI 'https://api.example.test' -Token $Expired -AuthMethod 'IdentityClientCredentials' -TenantId 'abc1234' -WebAppId 'webapp' -Credential $Cred
                Mock Get-EPMIdentityToken { throw 'Identity token request failed. HTTP 401 invalid_client' }
                Mock Invoke-RestMethod { throw 'should not be called' }
                { Invoke-EPMRestMethod -Method GET -Path 'Sets' } | Should -Throw '*Identity token request failed*'
                Should -Invoke Invoke-RestMethod -Times 0 -Exactly
            }
        }

        It 'throws for an expired client credentials token with no stored credential' {
            InModuleScope psEPM -Parameters @{ Expired = $script:expired } {
                param($Expired)
                $script:EPMSession = New-EPMSessionObject -BaseURI 'https://api.example.test' -Token $Expired -AuthMethod 'IdentityClientCredentials'
                Mock Get-EPMIdentityToken { throw 'should not renew' }
                Mock Invoke-RestMethod { throw 'should not be called' }
                { Invoke-EPMRestMethod -Method GET -Path 'Sets' } | Should -Throw '*Run New-EPMSession again*'
                Should -Invoke Invoke-RestMethod -Times 0 -Exactly
                Should -Invoke Get-EPMIdentityToken -Times 0 -Exactly
            }
        }

        It 'stores the credential in module scope but never shows it on Get-EPMSession' {
            $first = $script:fresh
            Mock -ModuleName psEPM Invoke-RestMethod -ParameterFilter { $Uri -like 'https://abc1234.id.cyberark.cloud/*' } { [pscustomobject]@{ access_token = $first } }
            New-EPMSession -TenantId 'abc1234' -WebAppId 'webapp' -Credential $script:cred -BaseURI 'https://api.example.test'
            foreach ($view in (Get-EPMSession), (Get-EPMSession -IncludeToken), (New-EPMSession -TenantId 'abc1234' -WebAppId 'webapp' -Credential $script:cred -BaseURI 'https://api.example.test' -PassThru)) {
                $names = $view.PSObject.Properties.Name
                $names | Should -Not -Contain 'Credential'
                $names | Should -Not -Contain 'ClientSecret'
                $names | Should -Not -Contain 'TenantId'
                $names | Should -Not -Contain 'WebAppId'
                ($view | Out-String) | Should -Not -BeLike '*fake-secret*'
            }
            (Get-EPMSession).PSObject.Properties.Name | Should -Not -Contain 'Token'
            InModuleScope psEPM {
                $script:EPMSession.Credential.UserName | Should -Be 'svc@example.test'
                $script:EPMSession.TenantId | Should -Be 'abc1234'
            }
        }

        It 'clears the stored credential and token on Close-EPMSession' {
            $first = $script:fresh
            Mock -ModuleName psEPM Invoke-RestMethod -ParameterFilter { $Uri -like 'https://abc1234.id.cyberark.cloud/*' } { [pscustomobject]@{ access_token = $first } }
            New-EPMSession -TenantId 'abc1234' -WebAppId 'webapp' -Credential $script:cred -BaseURI 'https://api.example.test'
            $held = InModuleScope psEPM { $script:EPMSession }
            Close-EPMSession
            $held.Credential | Should -BeNullOrEmpty
            $held.Token | Should -BeNullOrEmpty
            $held.TenantId | Should -BeNullOrEmpty
            InModuleScope psEPM { $script:EPMSession | Should -BeNullOrEmpty }
            Get-EPMSession | Should -BeNullOrEmpty
        }

        It 'does not keep a credential for a -Token session or after Use-EPMSession' {
            New-EPMSession -Token (ConvertTo-SecureString $script:fresh -AsPlainText -Force) -BaseURI 'https://api.example.test'
            InModuleScope psEPM { $script:EPMSession.Credential | Should -BeNullOrEmpty }
            $first = $script:fresh
            Mock -ModuleName psEPM Invoke-RestMethod -ParameterFilter { $Uri -like 'https://abc1234.id.cyberark.cloud/*' } { [pscustomobject]@{ access_token = $first } }
            New-EPMSession -TenantId 'abc1234' -WebAppId 'webapp' -Credential $script:cred -BaseURI 'https://api.example.test'
            Get-EPMSession -IncludeToken | Use-EPMSession
            InModuleScope psEPM { $script:EPMSession.Credential | Should -BeNullOrEmpty }
        }
    }
}
