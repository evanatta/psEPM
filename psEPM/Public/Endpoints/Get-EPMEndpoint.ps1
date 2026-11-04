function Get-EPMEndpoint {
    [CmdletBinding(DefaultParameterSetName = 'Search')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$SetId,

        [Parameter(Mandatory = $true, ParameterSetName = 'ById', ValueFromPipelineByPropertyName = $true)]
        [string]$EndpointId,

        [Parameter(Mandatory = $false, ParameterSetName = 'ById')]
        [ValidateSet('OsInfo', 'Hardware', 'Network', 'DomainInfo', 'TimeAndDate', 'UserGroupsInfo', 'InstalledProgramsInfo')]
        [string[]]$InventoryType,

        [Parameter(Mandatory = $false, ParameterSetName = 'Search')]
        [string]$Filter = '',

        [Parameter(Mandatory = $false, ParameterSetName = 'Search')]
        [string]$Name,

        [Parameter(Mandatory = $false, ParameterSetName = 'Search')]
        [ValidateSet('Windows', 'MacOS', 'Linux')]
        [string[]]$Platform,

        [Parameter(Mandatory = $false, ParameterSetName = 'Search')]
        [string]$SortBy = 'Name',

        [Parameter(Mandatory = $false, ParameterSetName = 'Search')]
        [ValidateSet('asc', 'desc')]
        [string]$SortDirection = 'asc',

        [Parameter(Mandatory = $false, ParameterSetName = 'Search')]
        [ValidateRange(1, 1000)]
        [int]$PageSize = 1000,

        [Parameter(Mandatory = $false, ParameterSetName = 'Search')]
        [int]$First = 0
    )

    process {
        if ($PSCmdlet.ParameterSetName -eq 'ById') {
            $inventoryFilter = ''
            if ($InventoryType) {
                $inventoryFilter = 'inventoryType IN {0}' -f ($InventoryType -join ',')
            }
            $item = Invoke-EPMRestMethod -Method POST -Path ('Sets/{0}/Endpoints/{1}/search' -f $SetId, $EndpointId) -Body @{ filter = $inventoryFilter }
            $item | Add-Member -MemberType NoteProperty -Name SetId -Value $SetId -Force
            $item | Add-Member -MemberType NoteProperty -Name EndpointId -Value $item.id -Force
            $item.PSObject.TypeNames.Insert(0, 'psEPM.EndpointDetail')
            return $item
        }

        $clauses = New-Object System.Collections.Generic.List[string]
        if ($Filter) { $clauses.Add($Filter) }
        if ($Name) { $clauses.Add(('name CONTAINS "{0}"' -f $Name)) }
        if ($Platform) { $clauses.Add(('platform IN {0}' -f ($Platform -join ','))) }
        $body = @{ filter = ($clauses -join ' AND ') }

        $query = @{ sortBy = $SortBy; sortDir = $SortDirection }
        $items = Invoke-EPMPagedRequest -Method POST -Path ('Sets/{0}/Endpoints/search' -f $SetId) -ItemProperty 'endpoints' -Query $query -Body $body -PageSize $PageSize -First $First
        foreach ($item in $items) {
            if ($null -eq $item.PSObject.Properties['setId']) {
                $item | Add-Member -MemberType NoteProperty -Name SetId -Value $SetId
            }
            $item | Add-Member -MemberType NoteProperty -Name EndpointId -Value $item.id -Force
            $item.PSObject.TypeNames.Insert(0, 'psEPM.Endpoint')
            $item
        }
    }
}
