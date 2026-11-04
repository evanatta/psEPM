function Get-EPMPolicy {
    [CmdletBinding(DefaultParameterSetName = 'Search')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$SetId,

        [Parameter(Mandatory = $true, ParameterSetName = 'ById', ValueFromPipelineByPropertyName = $true)]
        [string]$PolicyId,

        [Parameter(Mandatory = $false, ParameterSetName = 'Search')]
        [string]$Filter,

        [Parameter(Mandatory = $false, ParameterSetName = 'Search')]
        [string]$Name,

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
            $item = Invoke-EPMRestMethod -Method GET -Path ('Sets/{0}/Policies/Server/{1}' -f $SetId, $PolicyId)
            $item | Add-Member -MemberType NoteProperty -Name SetId -Value $SetId -Force
            $item.PSObject.TypeNames.Insert(0, 'psEPM.PolicyDetail')
            return $item
        }

        $clauses = New-Object System.Collections.Generic.List[string]
        if ($Filter) { $clauses.Add($Filter) }
        if ($Name) { $clauses.Add(('PolicyName CONTAINS "{0}"' -f $Name)) }
        $body = @{}
        if ($clauses.Count -gt 0) { $body.filter = ($clauses -join ' AND ') }

        $query = @{ sortBy = $SortBy; sortDir = $SortDirection }
        $items = Invoke-EPMPagedRequest -Method POST -Path ('Sets/{0}/Policies/Server/Search' -f $SetId) -ItemProperty 'Policies' -Query $query -Body $body -PageSize $PageSize -First $First
        foreach ($item in $items) {
            $item | Add-Member -MemberType NoteProperty -Name SetId -Value $SetId -Force
            $item.PSObject.TypeNames.Insert(0, 'psEPM.Policy')
            $item
        }
    }
}
