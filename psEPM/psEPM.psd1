@{
    RootModule           = 'psEPM.psm1'
    ModuleVersion        = '0.1.0'
    GUID                 = '2df18df8-f357-4415-8b10-5cac2904ccf3'
    Author               = 'EPM Scripts'
    Copyright            = '(c) EPM Scripts. MIT License.'
    Description          = 'PowerShell module for the Endpoint Privilege Manager REST API.'
    PowerShellVersion    = '5.1'
    CompatiblePSEditions = @('Desktop', 'Core')
    FunctionsToExport    = @(
        'New-EPMSession',
        'Get-EPMSession',
        'Use-EPMSession',
        'Close-EPMSession',
        'Get-EPMSet',
        'Get-EPMEndpoint',
        'Get-EPMEndpointInventory',
        'Get-EPMEndpointSummary',
        'Get-EPMEndpointGroup',
        'Get-EPMEndpointGroupValue',
        'New-EPMEndpointGroup',
        'Set-EPMEndpointGroup',
        'Remove-EPMEndpointGroup',
        'Add-EPMEndpointGroupMember',
        'Remove-EPMEndpointGroupMember',
        'Get-EPMPolicy',
        'New-EPMPolicy',
        'Set-EPMPolicy',
        'Remove-EPMPolicy',
        'Export-EPMPolicy',
        'Get-EPMApplicationGroup',
        'New-EPMApplicationGroup',
        'Set-EPMApplicationGroup',
        'Remove-EPMApplicationGroup',
        'Get-EPMAgentConfiguration',
        'Get-EPMThreatProtectionPolicy',
        'Get-EPMPolicyRecommendation',
        'Get-EPMEvent',
        'Get-EPMEventAggregation',
        'Get-EPMPolicyAudit',
        'Get-EPMPolicyAuditAggregation',
        'Get-EPMSignInAudit',
        'Get-EPMSignInAuditAggregation',
        'Get-EPMAdminAudit',
        'Get-EPMVideo',
        'Get-EPMApplicationCatalog',
        'Get-EPMFileInstance',
        'New-EPMReport',
        'Get-EPMAgentPackage',
        'Get-EPMEndpointPackage',
        'Get-EPMPackageConfiguration',
        'Get-EPMPackageUrl'
    )
    CmdletsToExport      = @()
    VariablesToExport    = @()
    AliasesToExport      = @()
    PrivateData          = @{
        PSData = @{
            Tags       = @('EPM', 'EndpointPrivilegeManager', 'REST', 'API')
            LicenseUri = 'https://opensource.org/licenses/MIT'
        }
    }
}
