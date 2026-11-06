function Get-EPMEndpointSummary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$SetId
    )

    process {
        $response = Invoke-EPMRestMethod -Method GET -Path ('Sets/{0}/Endpoints/Summary' -f $SetId)
        foreach ($item in @($response.summary)) {
            if ($null -eq $item) { continue }
            $item | Add-Member -MemberType NoteProperty -Name SetId -Value $SetId -Force
            $item.PSObject.TypeNames.Insert(0, 'psEPM.EndpointSummary')
            $item
        }
    }
}
