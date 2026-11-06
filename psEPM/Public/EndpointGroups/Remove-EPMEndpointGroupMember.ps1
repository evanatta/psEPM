function Remove-EPMEndpointGroupMember {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High', DefaultParameterSetName = 'ById')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$SetId,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$GroupId,

        [Parameter(Mandatory = $true, ParameterSetName = 'ById', ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$EndpointId,

        [Parameter(Mandatory = $true, ParameterSetName = 'ByFilter')]
        [string]$Filter
    )

    begin {
        $pending = [ordered]@{}
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq 'ByFilter') {
            if ([string]::IsNullOrWhiteSpace($Filter)) {
                $PSCmdlet.ThrowTerminatingError((New-Object System.Management.Automation.ErrorRecord((New-Object System.ArgumentException('Remove-EPMEndpointGroupMember requires a non-empty -Filter. An empty filter is not sent.')), 'EPMEmptyFilter', 'InvalidArgument', $GroupId)))
            }
            $body = @{ filter = $Filter.Trim() }
            $target = 'Set {0}, group {1}, members matching {2}' -f $SetId, $GroupId, $body.filter
            if (-not $PSCmdlet.ShouldProcess($target, 'Remove endpoints from group')) { return }
            $response = Invoke-EPMRestMethod -Method POST -Path ('Sets/{0}/Endpoints/Groups/{1}/members/remove' -f $SetId, $GroupId) -Body $body
            New-EPMMemberChange -SetId $SetId -GroupId $GroupId -Action Remove -Filter $body.filter -Response $response
            return
        }

        $key = '{0}|{1}' -f $SetId, $GroupId
        if (-not $pending.Contains($key)) {
            $pending[$key] = [pscustomobject]@{ SetId = $SetId; GroupId = $GroupId; Ids = (New-Object System.Collections.Generic.List[string]) }
        }
        foreach ($id in $EndpointId) {
            if (-not [string]::IsNullOrWhiteSpace($id) -and -not $pending[$key].Ids.Contains($id)) { $pending[$key].Ids.Add($id) }
        }
    }

    end {
        foreach ($entry in $pending.Values) {
            $ids = @($entry.Ids)
            for ($start = 0; $start -lt $ids.Count; $start += 5000) {
                $chunk = @($ids[$start..([math]::Min($start + 4999, $ids.Count - 1))])
                $target = 'Set {0}, group {1}, {2} endpoint(s): {3}' -f $entry.SetId, $entry.GroupId, $chunk.Count, ($chunk -join ',')
                if (-not $PSCmdlet.ShouldProcess($target, 'Remove endpoints from group')) { continue }
                $null = Invoke-EPMRestMethod -Method POST -Path ('Sets/{0}/Endpoints/Groups/{1}/members/ids/remove' -f $entry.SetId, $entry.GroupId) -Body (ConvertTo-EPMMemberIdBody -Id $chunk)
                New-EPMMemberChange -SetId $entry.SetId -GroupId $entry.GroupId -Action Remove -RequestedIds $chunk
            }
        }
    }
}
