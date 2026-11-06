function Get-EPMEndpointPackage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$SetId,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string[]]$EndpointId,

        [Parameter(Mandatory = $false)]
        [string]$Filter,

        [Parameter(Mandatory = $false)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Windows', 'MacOS', 'Linux')]
        [string[]]$Platform
    )

    process {
        $clauses = New-Object System.Collections.Generic.List[string]
        if ($Filter) { $clauses.Add($Filter) }
        if ($EndpointId) { $clauses.Add(('id IN {0}' -f ($EndpointId -join ','))) }
        if ($Name) { $clauses.Add(('name CONTAINS "{0}"' -f $Name)) }
        if ($Platform) {
            if ($Platform.Count -eq 1) {
                $clauses.Add(('platform EQ {0}' -f $Platform[0]))
            } else {
                $clauses.Add(('platform IN {0}' -f ($Platform -join ',')))
            }
        }
        $body = @{ filter = ($clauses -join ' AND ') }

        $response = Invoke-EPMRestMethod -Method POST -Path ('Sets/{0}/Endpoints/Packages' -f $SetId) -Body $body
        foreach ($item in @($response.packages)) {
            if ($null -eq $item) { continue }
            $item | Add-Member -MemberType NoteProperty -Name FilteredCount -Value $response.filteredCount -Force
            ConvertTo-EPMPackage -InputObject $item -SetId $SetId -TypeName 'psEPM.EndpointPackage'
        }
    }
}
