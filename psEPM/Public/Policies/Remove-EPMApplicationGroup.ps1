function Remove-EPMApplicationGroup {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$SetId,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('PolicyId')]
        [ValidateNotNullOrEmpty()]
        [string[]]$ApplicationGroupId
    )

    process {
        foreach ($id in $ApplicationGroupId) {
            $target = 'Set {0}, application group {1}' -f $SetId, $id
            if (-not $PSCmdlet.ShouldProcess($target, 'Delete application group')) { continue }
            $null = Invoke-EPMRestMethod -Method DELETE -Path ('Sets/{0}/Policies/ApplicationGroups/{1}' -f $SetId, $id)
            $result = [pscustomobject]@{ SetId = $SetId; ApplicationGroupId = $id }
            $result.PSObject.TypeNames.Insert(0, 'psEPM.ApplicationGroupRemoval')
            $result
        }
    }
}
