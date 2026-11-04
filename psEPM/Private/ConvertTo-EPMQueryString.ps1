function ConvertTo-EPMQueryString {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Parameters
    )

    $pairs = foreach ($key in ($Parameters.Keys | Sort-Object)) {
        $value = $Parameters[$key]
        if ($null -ne $value -and "$value" -ne '') {
            '{0}={1}' -f $key, [uri]::EscapeDataString([string]$value)
        }
    }
    if ($pairs) {
        '?' + ($pairs -join '&')
    } else {
        ''
    }
}
