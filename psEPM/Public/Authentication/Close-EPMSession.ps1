function Close-EPMSession {
    [CmdletBinding()]
    param()

    if ($null -ne $script:EPMSession) {
        foreach ($name in 'Token', 'Credential', 'TenantId', 'WebAppId') {
            if ($null -ne $script:EPMSession.PSObject.Properties[$name]) { $script:EPMSession.$name = $null }
        }
    }
    $script:EPMSession = $null
}
