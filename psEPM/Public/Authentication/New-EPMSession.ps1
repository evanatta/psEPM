function New-EPMSession {
    [CmdletBinding(DefaultParameterSetName = 'ClientCredentials')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientCredentials')]
        [ValidateNotNullOrEmpty()]
        [string]$TenantId,

        [Parameter(Mandatory = $true, ParameterSetName = 'ClientCredentials')]
        [ValidateNotNullOrEmpty()]
        [string]$WebAppId,

        [Parameter(Mandatory = $true, ParameterSetName = 'ClientCredentials')]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [Parameter(Mandatory = $true, ParameterSetName = 'Token')]
        [System.Security.SecureString]$Token,

        [Parameter(Mandatory = $true)]
        [ValidatePattern('^https://')]
        [string]$BaseURI,

        [Parameter(Mandatory = $false)]
        [switch]$PassThru
    )

    if ($PSCmdlet.ParameterSetName -eq 'ClientCredentials') {
        $user = $Credential.UserName
        $accessToken = Get-EPMIdentityToken -TenantId $TenantId -WebAppId $WebAppId -Credential $Credential
        $script:EPMSession = New-EPMSessionObject -BaseURI $BaseURI -Token $accessToken -AuthMethod 'IdentityClientCredentials' -User $user -TenantId $TenantId -WebAppId $WebAppId -Credential $Credential
        $accessToken = $null
    } else {
        $plain = (New-Object System.Management.Automation.PSCredential('token', $Token)).GetNetworkCredential().Password
        $script:EPMSession = New-EPMSessionObject -BaseURI $BaseURI -Token $plain -AuthMethod 'Token'
    }

    if ($PassThru) {
        Get-EPMSession
    }
}
