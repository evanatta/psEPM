function Get-EPMPolicyRecommendation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$SetId
    )

    process {
        $response = Invoke-EPMRestMethod -Method GET -Path ('Sets/{0}/Policies/Recommendations' -f $SetId)
        foreach ($item in @($response.Data)) {
            if ($null -eq $item) { continue }
            $item | Add-Member -MemberType NoteProperty -Name SetId -Value $SetId -Force
            $item.PSObject.TypeNames.Insert(0, 'psEPM.PolicyRecommendation')
            $item
        }
    }
}
