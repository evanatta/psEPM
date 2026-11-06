function ConvertTo-EPMMemberIdBody {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Id
    )

    $items = foreach ($value in $Id) { ConvertTo-Json -InputObject ([string]$value) -Compress }
    '{"membersIds":[' + ($items -join ',') + ']}'
}
