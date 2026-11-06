function New-EPMSessionObject {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BaseURI,

        [Parameter(Mandatory = $true)]
        [string]$Token,

        [Parameter(Mandatory = $false)]
        [string]$AuthMethod = 'IdentityClientCredentials',

        [Parameter(Mandatory = $false)]
        [string]$User,

        [Parameter(Mandatory = $false)]
        [string]$TenantId,

        [Parameter(Mandatory = $false)]
        [string]$WebAppId,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]$Credential
    )

    $base = $BaseURI.TrimEnd('/')
    if ($base -match '/API$') {
        $apiUri = $base
    } elseif ($base -match '\.epm\.cyberark\.com$') {
        $apiUri = '{0}/EPM/API' -f $base
    } else {
        $apiUri = '{0}/API' -f $base
    }

    $expiresAt = Get-EPMTokenExpiry -Token $Token
    if ($null -ne $expiresAt) { $expiresAt = $expiresAt.ToLocalTime() }
    $storedTenant = $null
    $storedWebApp = $null
    $storedCredential = $null
    if ($PSBoundParameters.ContainsKey('Credential')) {
        $storedTenant = $TenantId
        $storedWebApp = $WebAppId
        $storedCredential = $Credential
    }

    $session = [pscustomobject]@{
        BaseURI         = $base
        ApiURI          = $apiUri
        AuthMethod      = $AuthMethod
        User            = $User
        Token           = $Token
        TokenExpiresAt  = $expiresAt
        StartTime       = Get-Date
        LastCommand     = $null
        LastCommandTime = $null
        LastError       = $null
        TenantId        = $storedTenant
        WebAppId        = $storedWebApp
        Credential      = $storedCredential
    }
    $session.PSObject.TypeNames.Insert(0, 'psEPM.Session')
    $session
}
