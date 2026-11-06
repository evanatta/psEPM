function Uninstall-EPMEndpoint {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$SetId,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [ValidatePattern('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')]
        [string[]]$EndpointId,

        [Parameter(Mandatory = $false)]
        [string]$Filter
    )

    process {
        $endpointFilter = ConvertTo-EPMEndpointFilter -EndpointId $EndpointId -Filter $Filter
        if ([string]::IsNullOrWhiteSpace($endpointFilter)) {
            $PSCmdlet.ThrowTerminatingError((New-Object System.Management.Automation.ErrorRecord((New-Object System.ArgumentException('Uninstall-EPMEndpoint requires -EndpointId or a non-empty -Filter. An empty filter is not sent.')), 'EPMEmptyFilter', 'InvalidArgument', $SetId)))
        }

        $body = [ordered]@{ filter = $endpointFilter }
        $body.returnIds = $true
        $body.includeAll = $false
        $json = ConvertTo-EPMJson -InputObject $body

        $target = 'Set {0}, endpoints matching {1}' -f $SetId, $endpointFilter
        if (-not $PSCmdlet.ShouldProcess($target, 'Uninstall agents from endpoints')) { return }

        $response = Invoke-EPMRestMethod -Method POST -Path ('Sets/{0}/endpoints/uninstall' -f $SetId) -Body $json
        $change = New-EPMEndpointChange -SetId $SetId -Action Uninstall -Filter $endpointFilter -Response $response
        if (@($change.AppliedIds).Count -eq 0) {
            Write-Warning ('No endpoints were applied for {0} in set {1}.' -f $endpointFilter, $SetId)
        }
        $change
    }
}
