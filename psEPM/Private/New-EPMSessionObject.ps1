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
        [string]$User
    )

    $base = $BaseURI.TrimEnd('/')
    if ($base -match '/API$') {
        $apiUri = $base
    } elseif ($base -match '\.epm\.cyberark\.com$') {
        $apiUri = '{0}/EPM/API' -f $base
    } else {
        $apiUri = '{0}/API' -f $base
    }

    $session = [pscustomobject]@{
        BaseURI         = $base
        ApiURI          = $apiUri
        AuthMethod      = $AuthMethod
        User            = $User
        Token           = $Token
        StartTime       = Get-Date
        LastCommand     = $null
        LastCommandTime = $null
        LastError       = $null
    }
    $session.PSObject.TypeNames.Insert(0, 'psEPM.Session')
    $session
}
