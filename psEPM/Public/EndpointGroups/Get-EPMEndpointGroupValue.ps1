function Get-EPMEndpointGroupValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$SetId,

        [Parameter(Mandatory = $true)]
        [ValidateSet('siteName', 'version', 'is64Bit', 'model', 'network', 'platformVersion', 'organizationUnit', 'endpointType', 'platform', 'computerVendor', 'servicePack')]
        [string]$Entity,

        [Parameter(Mandatory = $false)]
        [string]$Filter = ''
    )

    process {
        $clauses = New-Object System.Collections.Generic.List[string]
        $clauses.Add(('entity EQ {0}' -f $Entity))
        if ($Filter) { $clauses.Add($Filter) }
        $response = Invoke-EPMRestMethod -Method POST -Path ('Sets/{0}/Endpoints/Groups/values/search' -f $SetId) -Body @{ filter = ($clauses -join ' AND ') }
        foreach ($item in @($response)) {
            if ($null -eq $item) { continue }
            $item | Add-Member -MemberType NoteProperty -Name SetId -Value $SetId -Force
            $item | Add-Member -MemberType NoteProperty -Name Entity -Value $Entity -Force
            $item.PSObject.TypeNames.Insert(0, 'psEPM.EndpointGroupValue')
            $item
        }
    }
}
