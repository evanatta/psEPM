function Get-EPMEndpointGroup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$SetId,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string[]]$GroupId,

        [Parameter(Mandatory = $false)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Static', 'Dynamic')]
        [string]$Type,

        [Parameter(Mandatory = $false)]
        [string]$Filter = '',

        [Parameter(Mandatory = $false)]
        [ValidateSet('name', 'Type')]
        [string]$SortBy = 'name',

        [Parameter(Mandatory = $false)]
        [ValidateSet('asc', 'desc')]
        [string]$SortDirection = 'desc',

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 1000)]
        [int]$PageSize = 1000,

        [Parameter(Mandatory = $false)]
        [int]$First = 0
    )

    process {
        $clauses = New-Object System.Collections.Generic.List[string]
        if ($Filter) { $clauses.Add($Filter) }
        $ids = @($GroupId | Where-Object { $_ })
        if ($ids.Count -eq 1) {
            $clauses.Add(('id EQ "{0}"' -f $ids[0]))
        } elseif ($ids.Count -gt 1) {
            $clauses.Add(('id IN {0}' -f ($ids -join ',')))
        }
        if ($Name) { $clauses.Add(('name CONTAINS "{0}"' -f $Name)) }
        if ($Type) { $clauses.Add(('type EQ {0}' -f $Type)) }
        $body = @{ filter = ($clauses -join ' AND ') }
        $query = @{ sortBy = $SortBy; sortDir = $SortDirection }

        try {
            $items = @(Invoke-EPMPagedRequest -Method POST -Path ('v2/Sets/{0}/Endpoints/groups/search' -f $SetId) -ItemProperty 'endpointGroups' -Query $query -Body $body -PageSize $PageSize -First $First)
        } catch {
            if ($_.Exception.Message -notmatch 'HTTP 404\b') { throw }
            Write-Verbose 'Endpoint group search v2 returned 404. Using v1.'
            $items = @(Invoke-EPMPagedRequest -Method POST -Path ('Sets/{0}/Endpoints/groups/search' -f $SetId) -Query $query -Body $body -PageSize $PageSize -First $First)
        }

        foreach ($item in $items) {
            if ($null -eq $item) { continue }
            $item | Add-Member -MemberType NoteProperty -Name SetId -Value $SetId -Force
            $item | Add-Member -MemberType NoteProperty -Name GroupId -Value $item.id -Force
            $item.PSObject.TypeNames.Insert(0, 'psEPM.EndpointGroup')
            $item
        }
    }
}
