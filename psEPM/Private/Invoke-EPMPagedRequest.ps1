function Invoke-EPMPagedRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('GET', 'POST')]
        [string]$Method,

        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [string]$ItemProperty,

        [Parameter(Mandatory = $false)]
        [hashtable]$Query = @{},

        [Parameter(Mandatory = $false)]
        [object]$Body,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 1000)]
        [int]$PageSize = 1000,

        [Parameter(Mandatory = $false)]
        [int]$Offset = 0,

        [Parameter(Mandatory = $false)]
        [int]$First = 0,

        [Parameter(Mandatory = $false)]
        [switch]$Cursor,

        [Parameter(Mandatory = $false)]
        [string]$CountProperty = 'filteredCount'
    )

    if ($Cursor) {
        $limit = $PageSize
        if ($First -gt 0 -and $First -lt $limit) { $limit = $First }
        $returned = 0
        $sent = 'start'
        $previousSignature = $null
        $total = $null
        while ($true) {
            $pageQuery = @{}
            foreach ($key in $Query.Keys) { $pageQuery[$key] = $Query[$key] }
            $pageQuery.limit = $limit
            $pageQuery.nextCursor = $sent
            $request = @{
                Method = $Method
                Path   = $Path + (ConvertTo-EPMQueryString -Parameters $pageQuery)
            }
            if ($PSBoundParameters.ContainsKey('Body')) { $request.Body = $Body }

            $response = Invoke-EPMRestMethod @request
            if ($ItemProperty) {
                $items = @($response.$ItemProperty | Where-Object { $null -ne $_ })
            } else {
                $items = @($response | Where-Object { $null -ne $_ })
            }
            if ($null -ne $response -and $null -ne $response.PSObject.Properties[$CountProperty]) { $total = [int]$response.$CountProperty }
            $next = [string]$response.nextCursor

            $signature = '{0}|{1}|{2}' -f $items.Count, (ConvertTo-Json -InputObject (@($items | Select-Object -First 1)) -Depth 4 -Compress), (ConvertTo-Json -InputObject (@($items | Select-Object -Last 1)) -Depth 4 -Compress)
            if ($null -ne $previousSignature -and $signature -eq $previousSignature) {
                Write-Verbose 'The API returned the same page again. Paging stopped.'
                break
            }
            $previousSignature = $signature

            foreach ($item in $items) {
                $item
                $returned++
                if ($First -gt 0 -and $returned -ge $First) { return }
            }

            if ($items.Count -eq 0) { break }
            if ($null -ne $total -and $returned -ge $total) { break }
            if ([string]::IsNullOrEmpty($next)) { break }
            if ($next -eq $sent) {
                Write-Verbose 'The API returned the same cursor again. Paging stopped.'
                break
            }
            $sent = $next
        }
        if ($null -ne $total -and $returned -lt $total) {
            Write-Warning ('Returned {0} of {1} results. The API did not return further pages. Use a narrower filter or a larger -PageSize.' -f $returned, $total)
        }
        return
    }

    $returned = 0
    $currentOffset = $Offset
    while ($true) {
        $pageQuery = @{}
        foreach ($key in $Query.Keys) { $pageQuery[$key] = $Query[$key] }
        $pageQuery.offset = $currentOffset
        $pageQuery.limit = $PageSize
        $request = @{
            Method = $Method
            Path   = $Path + (ConvertTo-EPMQueryString -Parameters $pageQuery)
        }
        if ($PSBoundParameters.ContainsKey('Body')) { $request.Body = $Body }

        $response = Invoke-EPMRestMethod @request
        if ($ItemProperty) {
            $items = @($response.$ItemProperty)
        } else {
            $items = @($response)
        }
        foreach ($item in $items) {
            $item
            $returned++
            if ($First -gt 0 -and $returned -ge $First) { return }
        }
        if ($items.Count -lt $PageSize) { return }
        $currentOffset += $items.Count
    }
}
