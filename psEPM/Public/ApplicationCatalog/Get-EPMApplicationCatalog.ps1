function Get-EPMApplicationCatalog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$SetId,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Windows', 'MacOS', 'Linux')]
        [string]$OperatingSystem,

        [Parameter(Mandatory = $false)]
        [string]$Filter,

        [Parameter(Mandatory = $false)]
        [ValidateSet('FirstSeen', 'NumOfComputers')]
        [string]$SortBy,

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
        $parts = New-Object System.Collections.Generic.List[string]
        if ($OperatingSystem) { $parts.Add(('operatingSystemType EQ {0}' -f $OperatingSystem)) }
        if (-not [string]::IsNullOrWhiteSpace($Filter)) { $parts.Add($Filter) }
        $text = ConvertTo-EPMEventFilter -Filter ($parts -join ' AND ')
        $body = @{}
        if ($text) { $body.filter = $text }
        $path = 'Sets/{0}/Files/Aggregations/search' -f $SetId

        if ($SortBy) {
            $limit = $PageSize
            if ($First -gt 0 -and $First -lt $limit) { $limit = $First }
            $query = @{ limit = $limit; sortBy = $SortBy; sortDir = $SortDirection }
            $response = Invoke-EPMRestMethod -Method POST -Path ($path + (ConvertTo-EPMQueryString -Parameters $query)) -Body $body
            $items = @($response.files | Where-Object { $null -ne $_ })
            if ($First -eq 0 -and $null -ne $response.filteredCount -and [int]$response.filteredCount -gt $items.Count) {
                Write-Warning ('Returned {0} of {1} results. A sorted search returns one page only. Use a narrower filter.' -f $items.Count, $response.filteredCount)
            }
        } else {
            $items = Invoke-EPMPagedRequest -Method POST -Path $path -ItemProperty 'files' -Body $body -PageSize $PageSize -First $First -Cursor
        }

        foreach ($item in $items) {
            if ($null -eq $item.PSObject.Properties['SetId']) { $item | Add-Member -MemberType NoteProperty -Name SetId -Value $SetId }
            $item.PSObject.TypeNames.Insert(0, 'psEPM.ApplicationCatalog')
            $item
        }
    }
}
