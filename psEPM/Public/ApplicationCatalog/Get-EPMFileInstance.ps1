function Get-EPMFileInstance {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$SetId,

        [Parameter(Mandatory = $false)]
        [datetime]$DateFrom,

        [Parameter(Mandatory = $false)]
        [datetime]$DateTo,

        [Parameter(Mandatory = $false)]
        [string]$Filter,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 1000)]
        [int]$PageSize = 1000,

        [Parameter(Mandatory = $false)]
        [int]$First = 0
    )

    process {
        $filterParameters = @{ Filter = $Filter }
        if ($PSBoundParameters.ContainsKey('DateFrom')) { $filterParameters.DateFrom = $DateFrom }
        if ($PSBoundParameters.ContainsKey('DateTo')) { $filterParameters.DateTo = $DateTo }
        $text = ConvertTo-EPMEventFilter @filterParameters
        $body = @{}
        if ($text) { $body.filter = $text }

        $items = Invoke-EPMPagedRequest -Method POST -Path ('Sets/{0}/Files/FileInstances/Search' -f $SetId) -ItemProperty 'fileInstances' -Body $body -PageSize $PageSize -First $First -Cursor
        foreach ($item in $items) {
            if ($null -eq $item.PSObject.Properties['SetId']) { $item | Add-Member -MemberType NoteProperty -Name SetId -Value $SetId }
            $item.PSObject.TypeNames.Insert(0, 'psEPM.FileInstance')
            $item
        }
    }
}
