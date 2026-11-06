function Get-EPMEventAggregation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$SetId,

        [Parameter(Mandatory = $false)]
        [datetime]$DateFrom,

        [Parameter(Mandatory = $false)]
        [datetime]$DateTo,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Launch', 'Block', 'Trust', 'ElevationRequest', 'ManualRequest', 'Installation', 'StartElevated', 'AttackAttempt')]
        [string[]]$EventType,

        [Parameter(Mandatory = $false)]
        [string]$Filter,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 1000)]
        [int]$PageSize = 1000,

        [Parameter(Mandatory = $false)]
        [int]$First = 0
    )

    process {
        $filterParameters = @{ EventType = $EventType; Filter = $Filter }
        if ($PSBoundParameters.ContainsKey('DateFrom')) { $filterParameters.DateFrom = $DateFrom }
        if ($PSBoundParameters.ContainsKey('DateTo')) { $filterParameters.DateTo = $DateTo }
        $text = ConvertTo-EPMEventFilter @filterParameters
        $body = @{}
        if ($text) { $body.filter = $text }

        $items = Invoke-EPMPagedRequest -Method POST -Path ('Sets/{0}/events/aggregations/search' -f $SetId) -ItemProperty 'events' -Body $body -PageSize $PageSize -First $First -Cursor
        foreach ($item in $items) {
            $item | Add-Member -MemberType NoteProperty -Name SetId -Value $SetId -Force
            $item.PSObject.TypeNames.Insert(0, 'psEPM.EventAggregation')
            $item
        }
    }
}
