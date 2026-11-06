function Move-EPMEndpoint {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$SetId,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [ValidatePattern('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')]
        [string[]]$EndpointId,

        [Parameter(Mandatory = $false)]
        [string]$Filter,

        [Parameter(Mandatory = $true)]
        [ValidatePattern('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')]
        [string]$TargetSetId
    )

    process {
        $endpointFilter = ConvertTo-EPMEndpointFilter -EndpointId $EndpointId -Filter $Filter
        if ([string]::IsNullOrWhiteSpace($endpointFilter)) {
            $PSCmdlet.ThrowTerminatingError((New-Object System.Management.Automation.ErrorRecord((New-Object System.ArgumentException('Move-EPMEndpoint requires -EndpointId or a non-empty -Filter. An empty filter is not sent.')), 'EPMEmptyFilter', 'InvalidArgument', $SetId)))
        }
        if ($TargetSetId -eq $SetId) {
            $PSCmdlet.ThrowTerminatingError((New-Object System.Management.Automation.ErrorRecord((New-Object System.ArgumentException('Move-EPMEndpoint requires a -TargetSetId different from -SetId.')), 'EPMSameSet', 'InvalidArgument', $SetId)))
        }
        $body = [ordered]@{ filter = $endpointFilter }
        $body.targetSet = $TargetSetId
        $body.returnIds = $true
        $body.includeAll = $false
        $json = ConvertTo-EPMJson -InputObject $body

        $target = 'Set {0}, endpoints matching {1}' -f $SetId, $endpointFilter
        if (-not $PSCmdlet.ShouldProcess($target, ('Move endpoints to set {0}' -f $TargetSetId))) { return }

        $response = Invoke-EPMRestMethod -Method POST -Path ('Sets/{0}/Endpoints/moveset' -f $SetId) -Body $json
        $change = New-EPMEndpointChange -SetId $SetId -Action Move -Filter $endpointFilter -Response $response -TargetSetId $TargetSetId
        if (@($change.AppliedIds).Count -eq 0) {
            Write-Warning ('No endpoints were applied for {0} in set {1}.' -f $endpointFilter, $SetId)
        }
        $change
    }
}
