function Use-EPMSession {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSTypeName('psEPM.SessionInfo')]
        $Session
    )

    process {
        if ([string]::IsNullOrEmpty($Session.Token)) {
            throw 'The session object has no token. Use Get-EPMSession -IncludeToken to capture a session you want to switch back to.'
        }
        $script:EPMSession = New-EPMSessionObject -BaseURI $Session.BaseURI -Token $Session.Token -AuthMethod $Session.AuthMethod -User $Session.User
    }
}
