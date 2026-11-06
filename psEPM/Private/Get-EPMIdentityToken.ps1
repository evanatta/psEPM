function Get-EPMIdentityToken {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TenantId,

        [Parameter(Mandatory = $true)]
        [string]$WebAppId,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]$Credential
    )

    $pair = '{0}:{1}' -f $Credential.UserName, $Credential.GetNetworkCredential().Password
    $basic = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($pair))
    $pair = $null
    $tokenRequest = @{
        Uri         = 'https://{0}.id.cyberark.cloud/oauth2/token/{1}' -f $TenantId, $WebAppId
        Method      = 'POST'
        Headers     = @{ Authorization = 'Basic {0}' -f $basic }
        ContentType = 'application/x-www-form-urlencoded'
        Body        = 'grant_type=client_credentials'
        ErrorAction = 'Stop'
    }
    $basic = $null
    try {
        $response = Invoke-RestMethod @tokenRequest
    } catch {
        $detail = Get-EPMErrorDetail -ErrorRecord $_
        throw ('Identity token request failed. HTTP {0} {1}' -f $detail.StatusCode, $detail.Message)
    } finally {
        $tokenRequest = $null
    }
    if ($null -eq $response -or [string]::IsNullOrEmpty($response.access_token)) {
        throw 'Identity token response did not contain an access_token.'
    }
    [string]$response.access_token
}
