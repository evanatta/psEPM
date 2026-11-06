function Get-EPMEndpointInventory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$SetId,

        [Parameter(Mandatory = $true)]
        [ValidateSet('OsInfo', 'Hardware', 'Network', 'DomainInfo', 'TimeAndDate', 'UserGroups', 'InstalledPrograms')]
        [string[]]$InventoryType,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string]$EndpointId,

        [Parameter(Mandatory = $false)]
        [string]$Filter = '',

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 1000)]
        [int]$PageSize = 1000,

        [Parameter(Mandatory = $false)]
        [int]$First = 0
    )

    process {
        $clauses = New-Object System.Collections.Generic.List[string]
        if ($EndpointId) { $clauses.Add(('endpointId EQ "{0}"' -f $EndpointId)) }
        if ($Filter) { $clauses.Add($Filter) }
        $body = @{ filter = ($clauses -join ' AND ') }

        foreach ($type in $InventoryType) {
            $items = @(Invoke-EPMPagedRequest -Method POST -Path ('Sets/{0}/Endpoints/inventory/{1}' -f $SetId, $type) -Body $body -PageSize $PageSize -First $First)
            foreach ($item in $items) {
                if ($null -eq $item) { continue }
                $item | Add-Member -MemberType NoteProperty -Name SetId -Value $SetId -Force
                $item | Add-Member -MemberType NoteProperty -Name EndpointId -Value $item.id -Force
                $item | Add-Member -MemberType NoteProperty -Name InventoryType -Value $type -Force
                $item.PSObject.TypeNames.Insert(0, 'psEPM.EndpointInventory')
                $item
            }
        }
    }
}
