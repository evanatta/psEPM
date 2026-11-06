function Get-EPMVideo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$SetId,

        [Parameter(Mandatory = $false)]
        [string]$Filter,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 1000)]
        [int]$PageSize = 1000,

        [Parameter(Mandatory = $false)]
        [int]$First = 0
    )

    process {
        $text = ConvertTo-EPMEventFilter -Filter $Filter
        $body = @{}
        if ($text) { $body.filter = $text }

        $items = Invoke-EPMPagedRequest -Method POST -Path ('Sets/{0}/Videos/Search' -f $SetId) -ItemProperty 'videos' -Body $body -PageSize $PageSize -First $First -Cursor
        foreach ($item in $items) {
            if ($null -eq $item.PSObject.Properties['SetId']) { $item | Add-Member -MemberType NoteProperty -Name SetId -Value $SetId }
            $item.PSObject.TypeNames.Insert(0, 'psEPM.Video')
            $item
        }
    }
}
