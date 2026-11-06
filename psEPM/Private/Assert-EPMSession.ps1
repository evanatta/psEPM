function Assert-EPMSession {
    [CmdletBinding()]
    param()

    if ($null -eq $script:EPMSession -or [string]::IsNullOrEmpty($script:EPMSession.Token)) {
        throw 'No EPM session. Run New-EPMSession first.'
    }

    $expiresAt = Get-EPMTokenExpiry -Token $script:EPMSession.Token
    if ($null -eq $expiresAt) { return }
    if ($expiresAt -gt [datetime]::UtcNow.AddSeconds(60)) { return }

    $session = $script:EPMSession
    $canRenew = $session.AuthMethod -eq 'IdentityClientCredentials' -and
        $null -ne $session.PSObject.Properties['Credential'] -and $null -ne $session.Credential -and
        -not [string]::IsNullOrEmpty($session.TenantId) -and -not [string]::IsNullOrEmpty($session.WebAppId)
    if (-not $canRenew) {
        $when = $expiresAt.ToString('yyyy-MM-dd HH:mm:ss', [System.Globalization.CultureInfo]::InvariantCulture)
        throw ('The EPM session token expired or expires within 60 seconds ({0} UTC), and this session cannot renew it. Run New-EPMSession again.' -f $when)
    }

    $newToken = Get-EPMIdentityToken -TenantId $session.TenantId -WebAppId $session.WebAppId -Credential $session.Credential
    $session.Token = $newToken
    $newExpiry = Get-EPMTokenExpiry -Token $newToken
    $session.TokenExpiresAt = $null
    if ($null -ne $newExpiry) { $session.TokenExpiresAt = $newExpiry.ToLocalTime() }
    $newToken = $null
}
