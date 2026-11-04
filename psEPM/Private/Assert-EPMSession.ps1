function Assert-EPMSession {
    [CmdletBinding()]
    param()

    if ($null -eq $script:EPMSession -or [string]::IsNullOrEmpty($script:EPMSession.Token)) {
        throw 'No EPM session. Run New-EPMSession first.'
    }
}
