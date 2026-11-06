function New-EPMEndpointChange {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SetId,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Upgrade', 'Move', 'Delete', 'Uninstall')]
        [string]$Action,

        [Parameter(Mandatory = $true)]
        [string]$Filter,

        [Parameter(Mandatory = $false)]
        [object]$Response,

        [Parameter(Mandatory = $false)]
        [string]$TargetSetId
    )

    $applied = @()
    $statuses = $null
    if ($null -ne $Response) {
        $applied = @($Response.appliedIds | Where-Object { $_ } | ForEach-Object { [string]$_ })
        $statuses = $Response.statuses
    }
    $result = [ordered]@{
        SetId      = $SetId
        Action     = $Action
        Filter     = $Filter
        AppliedIds = $applied
        Statuses   = $statuses
    }
    if ($Action -eq 'Move') { $result.TargetSetId = $TargetSetId }
    $item = [pscustomobject]$result
    $item.PSObject.TypeNames.Insert(0, 'psEPM.EndpointChange')
    $item
}
