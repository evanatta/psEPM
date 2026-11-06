function New-EPMMemberChange {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SetId,

        [Parameter(Mandatory = $true)]
        [string]$GroupId,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Add', 'Remove')]
        [string]$Action,

        [Parameter(Mandatory = $false)]
        [string]$Filter,

        [Parameter(Mandatory = $false)]
        [string[]]$RequestedIds,

        [Parameter(Mandatory = $false)]
        [object]$Response
    )

    $applied = @()
    if ($null -ne $Response -and -not ($Response -is [bool])) {
        $applied = @($Response | Where-Object { $_ } | ForEach-Object { [string]$_ })
    }
    $result = [pscustomobject]@{
        SetId        = $SetId
        GroupId      = $GroupId
        Action       = $Action
        Filter       = $Filter
        RequestedIds = @($RequestedIds)
        AppliedIds   = $applied
    }
    $result.PSObject.TypeNames.Insert(0, 'psEPM.EndpointGroupMemberChange')
    $result
}
