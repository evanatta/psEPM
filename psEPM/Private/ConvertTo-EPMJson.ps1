function ConvertTo-EPMJson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [object]$InputObject,

        [Parameter(Mandatory = $false)]
        [string[]]$ExcludeProperty = @(),

        [Parameter(Mandatory = $false)]
        [int]$Depth = 0
    )

    if ($Depth -gt 64) { throw 'ConvertTo-EPMJson: object is nested too deeply.' }
    if ($null -eq $InputObject) { return 'null' }

    $value = $InputObject
    if ($value -is [System.Management.Automation.PSObject] -and -not ($value.PSObject.BaseObject -is [System.Management.Automation.PSCustomObject])) {
        $value = $value.PSObject.BaseObject
    }

    if ($value -is [string] -or $value -is [char] -or $value -is [guid] -or $value -is [uri]) {
        return (ConvertTo-Json -InputObject ([string]$value) -Compress)
    }
    if ($value -is [bool]) {
        if ($value) { return 'true' }
        return 'false'
    }
    if ($value -is [enum]) {
        return ([string][int64]$value)
    }
    if ($value -is [datetime]) {
        return (ConvertTo-Json -InputObject ($value.ToString('o', [System.Globalization.CultureInfo]::InvariantCulture)) -Compress)
    }
    if ($value -is [byte] -or $value -is [sbyte] -or $value -is [int16] -or $value -is [uint16] -or $value -is [int] -or $value -is [uint32] -or $value -is [int64] -or $value -is [uint64] -or $value -is [double] -or $value -is [single] -or $value -is [decimal]) {
        return ([System.Convert]::ToString($value, [System.Globalization.CultureInfo]::InvariantCulture))
    }

    $next = $Depth + 1
    if ($value -is [System.Collections.IDictionary]) {
        $pairs = foreach ($key in $value.Keys) {
            if ($ExcludeProperty -contains [string]$key) { continue }
            (ConvertTo-Json -InputObject ([string]$key) -Compress) + ':' + (ConvertTo-EPMJson -InputObject $value[$key] -Depth $next)
        }
        return ('{' + (@($pairs) -join ',') + '}')
    }
    if ($value -is [System.Collections.IEnumerable]) {
        $items = foreach ($element in $value) { ConvertTo-EPMJson -InputObject $element -Depth $next }
        return ('[' + (@($items) -join ',') + ']')
    }

    $pairs = foreach ($property in $value.PSObject.Properties) {
        if ($property.MemberType -notin 'NoteProperty', 'Property') { continue }
        if ($ExcludeProperty -contains $property.Name) { continue }
        (ConvertTo-Json -InputObject $property.Name -Compress) + ':' + (ConvertTo-EPMJson -InputObject $property.Value -Depth $next)
    }
    '{' + (@($pairs) -join ',') + '}'
}
