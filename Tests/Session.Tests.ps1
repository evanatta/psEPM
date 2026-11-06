BeforeAll {
    Import-Module (Join-Path (Split-Path -Parent $PSScriptRoot) 'psEPM/psEPM.psd1') -Force
}

Describe 'New-EPMSession' {
    BeforeEach {
        Close-EPMSession
    }

    Context 'client credentials' {
        BeforeAll {
            Mock -ModuleName psEPM Invoke-RestMethod { [pscustomobject]@{ access_token = 'fake-access-token'; token_type = 'Bearer' } }
            $secret = ConvertTo-SecureString 'fake-secret' -AsPlainText -Force
            $script:cred = New-Object System.Management.Automation.PSCredential('svc@example.test', $secret)
        }

        It 'posts to the Identity token endpoint with a Basic header' {
            New-EPMSession -TenantId 'abc1234' -WebAppId 'webapp' -Credential $script:cred -BaseURI 'https://api.example.test'
            $expected = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('svc@example.test:fake-secret'))
            Should -Invoke -ModuleName psEPM Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
                $Uri -eq 'https://abc1234.id.cyberark.cloud/oauth2/token/webapp' -and
                $Method -eq 'POST' -and
                $Headers.Authorization -eq $expected -and
                $Body -match 'grant_type=client_credentials'
            }
        }

        It 'stores the session without exposing the token by default' {
            New-EPMSession -TenantId 'abc1234' -WebAppId 'webapp' -Credential $script:cred -BaseURI 'https://api.example.test/'
            $session = Get-EPMSession
            $session.ApiURI | Should -Be 'https://api.example.test/API'
            $session.AuthMethod | Should -Be 'IdentityClientCredentials'
            $session.PSObject.Properties.Name | Should -Not -Contain 'Token'
            (Get-EPMSession -IncludeToken).Token | Should -Be 'fake-access-token'
        }

        It 'uses /API on the regional API host' {
            New-EPMSession -TenantId 'abc1234' -WebAppId 'webapp' -Credential $script:cred -BaseURI 'https://api-na.epm.cyberark.cloud'
            (Get-EPMSession).ApiURI | Should -Be 'https://api-na.epm.cyberark.cloud/API'
        }

        It 'uses /EPM/API on a tenant manager host' {
            New-EPMSession -TenantId 'abc1234' -WebAppId 'webapp' -Credential $script:cred -BaseURI 'https://na123.epm.cyberark.com'
            (Get-EPMSession).ApiURI | Should -Be 'https://na123.epm.cyberark.com/EPM/API'
        }

        It 'keeps an explicit API path' {
            New-EPMSession -TenantId 'abc1234' -WebAppId 'webapp' -Credential $script:cred -BaseURI 'https://na123.epm.cyberark.com/EPM/API'
            (Get-EPMSession).ApiURI | Should -Be 'https://na123.epm.cyberark.com/EPM/API'
        }
    }

    Context 'token override' {
        It 'creates a session from a supplied token' {
            $token = ConvertTo-SecureString 'fake-token' -AsPlainText -Force
            New-EPMSession -Token $token -BaseURI 'https://api.example.test'
            (Get-EPMSession -IncludeToken).Token | Should -Be 'fake-token'
            (Get-EPMSession).AuthMethod | Should -Be 'Token'
        }
    }

    It 'requires https' {
        $token = ConvertTo-SecureString 'fake-token' -AsPlainText -Force
        { New-EPMSession -Token $token -BaseURI 'http://api.example.test' } | Should -Throw
    }
}

Describe 'Use-EPMSession and Close-EPMSession' {
    It 'switches back to a saved session' {
        $token = ConvertTo-SecureString 'first-token' -AsPlainText -Force
        New-EPMSession -Token $token -BaseURI 'https://one.example.test'
        $saved = Get-EPMSession -IncludeToken
        $other = ConvertTo-SecureString 'second-token' -AsPlainText -Force
        New-EPMSession -Token $other -BaseURI 'https://two.example.test'
        $saved | Use-EPMSession
        (Get-EPMSession -IncludeToken).Token | Should -Be 'first-token'
    }

    It 'clears the session' {
        Close-EPMSession
        Get-EPMSession | Should -BeNullOrEmpty
        { Get-EPMSet } | Should -Throw '*New-EPMSession*'
    }
}
