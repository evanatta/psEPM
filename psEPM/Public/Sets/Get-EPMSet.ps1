function Get-EPMSet {
    [CmdletBinding(DefaultParameterSetName = 'All')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'ById', ValueFromPipelineByPropertyName = $true)]
        [string[]]$SetId,

        [Parameter(Mandatory = $false, ParameterSetName = 'All', Position = 0)]
        [string]$Name
    )

    begin {
        $allSets = @(Invoke-EPMPagedRequest -Method GET -Path 'Sets' -ItemProperty 'Sets' -PageSize 1000)
        foreach ($item in $allSets) {
            if ($null -eq $item.PSObject.Properties['SetId']) {
                $item | Add-Member -MemberType NoteProperty -Name SetId -Value $item.Id
            }
            $item.PSObject.TypeNames.Insert(0, 'psEPM.Set')
        }
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq 'ById') {
            foreach ($id in $SetId) {
                $match = @($allSets | Where-Object { $_.SetId -eq $id })
                if ($match.Count -eq 0) {
                    Write-Error ('Set {0} was not found or is not visible to this session.' -f $id)
                }
                $match
            }
        } elseif ($Name) {
            $allSets | Where-Object { $_.Name -like $Name }
        } else {
            $allSets
        }
    }
}
