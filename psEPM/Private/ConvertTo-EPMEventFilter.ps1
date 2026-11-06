function ConvertTo-EPMEventFilter {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $false)]
        [object]$DateFrom,

        [Parameter(Mandatory = $false)]
        [object]$DateTo,

        [Parameter(Mandatory = $false)]
        [string[]]$EventType,

        [Parameter(Mandatory = $false)]
        [string]$Filter
    )

    $culture = [System.Globalization.CultureInfo]::InvariantCulture
    $clauses = New-Object System.Collections.Generic.List[string]
    if ($null -ne $DateFrom) { $clauses.Add(('arrivalTime GE {0}' -f ([datetime]$DateFrom).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ', $culture))) }
    if ($null -ne $DateTo) { $clauses.Add(('arrivalTime LE {0}' -f ([datetime]$DateTo).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ', $culture))) }
    $types = @($EventType | Where-Object { $_ } | Select-Object -Unique)
    if ($types.Count -gt 0) { $clauses.Add(('eventType IN {0}' -f ($types -join ','))) }
    if (-not [string]::IsNullOrWhiteSpace($Filter)) { $clauses.Add($Filter) }
    $clauses -join ' AND '
}
