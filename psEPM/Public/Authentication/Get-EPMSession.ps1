function Get-EPMSession {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$IncludeToken
    )

    if ($null -eq $script:EPMSession) {
        return
    }
    $properties = 'BaseURI', 'ApiURI', 'AuthMethod', 'User', 'TokenExpiresAt', 'StartTime', 'LastCommand', 'LastCommandTime', 'LastError'
    if ($IncludeToken) {
        $properties += 'Token'
    }
    $view = $script:EPMSession | Select-Object -Property $properties
    $view | Add-Member -MemberType NoteProperty -Name ElapsedTime -Value ((Get-Date) - $script:EPMSession.StartTime)
    $view.PSObject.TypeNames.Insert(0, 'psEPM.SessionInfo')
    $view
}
