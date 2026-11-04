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

    $session = [pscustomobject]@{
        BaseURI         = $BaseURI.TrimEnd('/')
        ApiURI          = '{0}/EPM/API' -f $BaseURI.TrimEnd('/')
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
