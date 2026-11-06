function ConvertTo-EPMEndpointFilter {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $false)]
        [string[]]$EndpointId,

        [Parameter(Mandatory = $false)]
        [string]$Filter
    )

    $clauses = New-Object System.Collections.Generic.List[string]
    $ids = @($EndpointId | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { $_.Trim() } | Select-Object -Unique)
    if ($ids.Count -eq 1) {
        $clauses.Add(('id EQ "{0}"' -f $ids[0]))
    } elseif ($ids.Count -gt 1) {
        $clauses.Add(('id IN {0}' -f ($ids -join ',')))
    }
    if (-not [string]::IsNullOrWhiteSpace($Filter)) { $clauses.Add($Filter.Trim()) }
    $clauses -join ' AND '
}
