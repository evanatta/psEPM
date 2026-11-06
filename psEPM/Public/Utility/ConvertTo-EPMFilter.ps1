function ConvertTo-EPMFilter {
    [CmdletBinding(DefaultParameterSetName = 'Clause')]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'Clause')]
        [string]$Property,

        [Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'Clause')]
        [ValidateSet('EQ', 'NE', 'CONTAINS', 'NOTCONTAINS', 'STARTSWITH', 'ENDSWITH', 'IN', 'NOTIN', 'GT', 'GE', 'LT', 'LE')]
        [string]$Operator,

        [Parameter(Mandatory = $true, Position = 2, ParameterSetName = 'Clause')]
        [AllowEmptyString()]
        [AllowEmptyCollection()]
        [object[]]$Value,

        [Parameter(Mandatory = $true, ParameterSetName = 'InputObject', ValueFromPipeline = $true)]
        [object[]]$InputObject
    )

    begin {
        $operators = 'EQ', 'NE', 'CONTAINS', 'NOTCONTAINS', 'STARTSWITH', 'ENDSWITH', 'IN', 'NOTIN', 'GT', 'GE', 'LT', 'LE'
        $clauses = New-Object System.Collections.Generic.List[string]

        $fail = {
            param([string]$Message, [string]$ErrorId, [object]$Target)
            $PSCmdlet.ThrowTerminatingError((New-Object System.Management.Automation.ErrorRecord((New-Object System.ArgumentException($Message)), $ErrorId, 'InvalidArgument', $Target)))
        }

        $formatValue = {
            param([object]$Item, [string]$Op, [string]$Name)
            if ($null -eq $Item) { & $fail ('A value for "{0}" is null.' -f $Name) 'EPMFilterEmptyValue' $Name }
            if ($Item -is [System.Management.Automation.PSObject]) { $Item = $Item.PSObject.BaseObject }
            if ($Item -is [bool]) {
                if ($Item) { return 'true' }
                return 'false'
            }
            if ($Item -is [datetime]) {
                return $Item.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ', [System.Globalization.CultureInfo]::InvariantCulture)
            }
            if ($Item -is [byte] -or $Item -is [int16] -or $Item -is [int] -or $Item -is [int64] -or $Item -is [uint16] -or $Item -is [uint32] -or $Item -is [uint64] -or $Item -is [double] -or $Item -is [single] -or $Item -is [decimal]) {
                return [System.Convert]::ToString($Item, [System.Globalization.CultureInfo]::InvariantCulture)
            }
            $text = [string]$Item
            if ([string]::IsNullOrWhiteSpace($text)) { & $fail ('A value for "{0}" is empty or blank.' -f $Name) 'EPMFilterEmptyValue' $Name }
            if ($text.Contains('"')) { & $fail ('A value for "{0}" contains a double quote, which is not allowed in a filter value.' -f $Name) 'EPMFilterQuote' $text }
            if ($text.EndsWith('\')) { & $fail ('A value for "{0}" ends with a backslash, which is not allowed in a filter value.' -f $Name) 'EPMFilterBackslash' $text }
            if ($Op -eq 'IN' -or $Op -eq 'NOTIN') {
                if ($text -match '[\s,()]') { return ('"{0}"' -f $text) }
                return $text
            }
            '"{0}"' -f $text
        }

        $addClause = {
            param([string]$Name, [string]$Op, [object[]]$Values)
            if ([string]::IsNullOrWhiteSpace($Name)) { & $fail 'The filter property is empty or blank.' 'EPMFilterEmptyProperty' $Name }
            $Name = $Name.Trim()
            if ($Name -notmatch '^[A-Za-z_][A-Za-z0-9_]*(\.[A-Za-z_][A-Za-z0-9_]*)*$') { & $fail ('The filter property "{0}" is not a valid field name.' -f $Name) 'EPMFilterProperty' $Name }
            if ([string]::IsNullOrWhiteSpace($Op)) { & $fail ('No operator was given for "{0}".' -f $Name) 'EPMFilterOperator' $Name }
            $Op = $Op.Trim().ToUpperInvariant()
            if ($operators -notcontains $Op) { & $fail ('The operator "{0}" is not supported. Use one of: {1}.' -f $Op, ($operators -join ', ')) 'EPMFilterOperator' $Op }
            $items = @($Values | ForEach-Object { $_ })
            if ($items.Count -eq 0) { & $fail ('No value was given for "{0}".' -f $Name) 'EPMFilterEmptyValue' $Name }
            if ($Op -ne 'IN' -and $Op -ne 'NOTIN' -and $items.Count -gt 1) { & $fail ('{0} takes one value. Use IN or NOTIN for a list.' -f $Op) 'EPMFilterValueCount' $Name }
            $formatted = foreach ($item in $items) { & $formatValue $item $Op $Name }
            $clauses.Add(('{0} {1} {2}' -f $Name, $Op, (@($formatted) -join ',')))
        }
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq 'Clause') {
            & $addClause $Property $Operator $Value
            return
        }
        foreach ($entry in $InputObject) {
            if ($null -eq $entry) { continue }
            if ($entry -is [System.Collections.IDictionary]) {
                $name = $entry['Property']
                $op = $entry['Operator']
                $values = $entry['Value']
                $hasValue = $entry.Contains('Value')
            } else {
                $name = $entry.Property
                $op = $entry.Operator
                $values = $entry.Value
                $hasValue = $null -ne $entry.PSObject.Properties['Value']
            }
            if (-not $hasValue) { & $fail ('No value was given for "{0}".' -f $name) 'EPMFilterEmptyValue' $name }
            if ($null -eq $values) { $values = @(, $null) }
            & $addClause ([string]$name) ([string]$op) @($values)
        }
    }

    end {
        if ($clauses.Count -eq 0) {
            $PSCmdlet.ThrowTerminatingError((New-Object System.Management.Automation.ErrorRecord((New-Object System.ArgumentException('No filter clauses were given.')), 'EPMFilterEmpty', 'InvalidArgument', $null)))
        }
        $clauses -join ' AND '
    }
}
