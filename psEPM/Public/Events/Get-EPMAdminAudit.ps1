function Get-EPMAdminAudit {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$SetId,

        [Parameter(Mandatory = $false)]
        [datetime]$DateFrom,

        [Parameter(Mandatory = $false)]
        [datetime]$DateTo,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 500)]
        [int]$PageSize = 500,

        [Parameter(Mandatory = $false)]
        [int]$First = 0
    )

    process {
        $culture = [System.Globalization.CultureInfo]::InvariantCulture
        $format = 'yyyy-MM-ddTHH:mm:ssZ'
        $now = [datetime]::UtcNow
        $hasFrom = $PSBoundParameters.ContainsKey('DateFrom')
        $hasTo = $PSBoundParameters.ContainsKey('DateTo')
        $query = @{}
        if ($hasFrom) {
            $query.DateFrom = $DateFrom.ToUniversalTime().ToString($format, $culture)
        } elseif (-not $hasTo) {
            $query.DateFrom = $now.AddDays(-1).ToString($format, $culture)
        }
        if ($hasTo) {
            $query.DateTo = $DateTo.ToUniversalTime().ToString($format, $culture)
        } else {
            $query.DateTo = $now.ToString($format, $culture)
        }

        $items = Invoke-EPMPagedRequest -Method GET -Path ('Sets/{0}/AdminAudit' -f $SetId) -ItemProperty 'AdminAudits' -Query $query -PageSize $PageSize -First $First
        foreach ($item in $items) {
            if ($null -eq $item) { continue }
            if ($null -eq $item.PSObject.Properties['SetId']) { $item | Add-Member -MemberType NoteProperty -Name SetId -Value $SetId }
            $item.PSObject.TypeNames.Insert(0, 'psEPM.AdminAudit')
            $item
        }
    }
}
