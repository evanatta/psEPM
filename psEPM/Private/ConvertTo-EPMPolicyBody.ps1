function ConvertTo-EPMPolicyBody {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Policy
    )

    if ($Policy -is [string]) { return $Policy }
    $definition = $Policy
    $hasType = $false
    if ($Policy -is [System.Collections.IDictionary]) {
        $hasType = $Policy.Contains('PolicyType')
        if (-not $hasType -and $Policy.Contains('Policy')) { $definition = $Policy['Policy'] }
    } else {
        $hasType = $null -ne $Policy.PSObject.Properties['PolicyType']
        if (-not $hasType -and $null -ne $Policy.PSObject.Properties['Policy']) { $definition = $Policy.Policy }
    }
    ConvertTo-EPMJson -InputObject $definition -ExcludeProperty 'SetId', 'PolicyId', 'ApplicationGroupId'
}
