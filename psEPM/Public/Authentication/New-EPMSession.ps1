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
        $pair = '{0}:{1}' -f $user, $Credential.GetNetworkCredential().Password
        $basic = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($pair))
        $pair = $null
        $tokenRequest = @{
            Uri         = 'https://{0}.id.cyberark.cloud/oauth2/token/{1}' -f $TenantId, $WebAppId
            Method      = 'POST'
            Headers     = @{ Authorization = 'Basic {0}' -f $basic }
            ContentType = 'application/x-www-form-urlencoded'
            Body        = 'grant_type=client_credentials&scope=all'
            ErrorAction = 'Stop'
        }
        try {
            $response = Invoke-RestMethod @tokenRequest
        } catch {
            $detail = Get-EPMErrorDetail -ErrorRecord $_
            throw ('Identity token request failed. HTTP {0} {1}' -f $detail.StatusCode, $detail.Message)
        }
        if ([string]::IsNullOrEmpty($response.access_token)) {
            throw 'Identity token response did not contain an access_token.'
        }
        $script:EPMSession = New-EPMSessionObject -BaseURI $BaseURI -Token $response.access_token -AuthMethod 'IdentityClientCredentials' -User $user
    } else {
        $plain = (New-Object System.Management.Automation.PSCredential('token', $Token)).GetNetworkCredential().Password
        $script:EPMSession = New-EPMSessionObject -BaseURI $BaseURI -Token $plain -AuthMethod 'Token'
    }

    if ($PassThru) {
        Get-EPMSession
    }
}
