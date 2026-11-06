function Remove-EPMPolicy {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$SetId,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$PolicyId
    )

    process {
        foreach ($id in $PolicyId) {
            $target = 'Set {0}, policy {1}' -f $SetId, $id
            if (-not $PSCmdlet.ShouldProcess($target, 'Delete policy')) { continue }
            $null = Invoke-EPMRestMethod -Method DELETE -Path ('Sets/{0}/Policies/Server/{1}' -f $SetId, $id)
            $result = [pscustomobject]@{ SetId = $SetId; PolicyId = $id }
            $result.PSObject.TypeNames.Insert(0, 'psEPM.PolicyRemoval')
            $result
        }
    }
}
