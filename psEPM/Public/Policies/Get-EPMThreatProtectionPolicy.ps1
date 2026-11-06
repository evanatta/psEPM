function Get-EPMThreatProtectionPolicy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$SetId,

        [Parameter(Mandatory = $false)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [string]$Category
    )

    process {
        $response = Invoke-EPMRestMethod -Method GET -Path ('Sets/{0}/Policies/ThreatProtection' -f $SetId)
        foreach ($item in @($response)) {
            if ($null -eq $item) { continue }
            if ($Name -and $item.Name -notlike $Name) { continue }
            if ($Category -and $item.CategoryName -notlike $Category) { continue }
            $item | Add-Member -MemberType NoteProperty -Name SetId -Value $SetId -Force
            $item | Add-Member -MemberType NoteProperty -Name PolicyId -Value $item.Id -Force
            $item.PSObject.TypeNames.Insert(0, 'psEPM.ThreatProtectionPolicy')
            $item
        }
    }
}
