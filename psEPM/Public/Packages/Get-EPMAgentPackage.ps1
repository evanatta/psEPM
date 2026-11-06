function Get-EPMAgentPackage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$SetId,

        [Parameter(Mandatory = $false)]
        [string]$Filter,

        [Parameter(Mandatory = $false)]
        [string[]]$PackageId,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Windows', 'MacOS', 'Linux', 'Tools')]
        [string[]]$Platform,

        [Parameter(Mandatory = $false)]
        [switch]$Latest
    )

    process {
        $clauses = New-Object System.Collections.Generic.List[string]
        if ($Filter) { $clauses.Add($Filter) }
        if ($PackageId) { $clauses.Add(('id IN {0}' -f ($PackageId -join ','))) }
        if ($Platform) {
            if ($Platform.Count -eq 1) {
                $clauses.Add(('platform EQ {0}' -f $Platform[0]))
            } else {
                $clauses.Add(('platform IN {0}' -f ($Platform -join ',')))
            }
        }
        $body = @{ filter = ($clauses -join ' AND ') }

        $response = Invoke-EPMRestMethod -Method POST -Path ('Sets/{0}/packages/search' -f $SetId) -Body $body
        foreach ($item in @($response.packages)) {
            if ($null -eq $item) { continue }
            if ($Latest -and $item.packageType -ne 'latest') { continue }
            ConvertTo-EPMPackage -InputObject $item -SetId $SetId -TypeName 'psEPM.AgentPackage'
        }
    }
}
