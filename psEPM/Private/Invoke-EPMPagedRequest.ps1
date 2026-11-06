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
        [int]$First = 0
    )

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
