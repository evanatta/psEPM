function Update-EPMEndpoint {
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
        [ValidateSet('Windows', 'MacOS', 'Linux')]
        [string]$Platform,

        [Parameter(Mandatory = $true)]
        [ValidateSet('x64', 'arm64')]
        [string]$Architecture,

        [Parameter(Mandatory = $true)]
        [ValidatePattern('^[0-9]+(\.[0-9]+){1,3}$')]
        [string]$Version
    )

    process {
        $endpointFilter = ConvertTo-EPMEndpointFilter -EndpointId $EndpointId -Filter $Filter
        if ([string]::IsNullOrWhiteSpace($endpointFilter)) {
            $PSCmdlet.ThrowTerminatingError((New-Object System.Management.Automation.ErrorRecord((New-Object System.ArgumentException('Update-EPMEndpoint requires -EndpointId or a non-empty -Filter. An empty filter is not sent.')), 'EPMEmptyFilter', 'InvalidArgument', $SetId)))
        }

        $body = [ordered]@{ filter = $endpointFilter }
        $body.versions = @([ordered]@{ platform = $Platform; architecture = $Architecture; version = $Version })
        $body.returnIds = $true
        $body.includeAll = $false
        $json = ConvertTo-EPMJson -InputObject $body

        $target = 'Set {0}, endpoints matching {1}' -f $SetId, $endpointFilter
        if (-not $PSCmdlet.ShouldProcess($target, ('Upgrade endpoints to {0} {1} {2}' -f $Platform, $Architecture, $Version))) { return }

        $response = Invoke-EPMRestMethod -Method POST -Path ('Sets/{0}/endpoints/upgrade' -f $SetId) -Body $json
        $change = New-EPMEndpointChange -SetId $SetId -Action Upgrade -Filter $endpointFilter -Response $response
        if (@($change.AppliedIds).Count -eq 0) {
            Write-Warning ('No endpoints were applied for {0} in set {1}.' -f $endpointFilter, $SetId)
        }
        $change
    }
}
