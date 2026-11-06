function Remove-EPMEndpointGroup {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High', DefaultParameterSetName = 'ByFilter')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$SetId,

        [Parameter(Mandatory = $true, ParameterSetName = 'ById', ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$GroupId,

        [Parameter(Mandatory = $false, ParameterSetName = 'ById')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ByFilter')]
        [string]$Filter
    )

    process {
        $clauses = New-Object System.Collections.Generic.List[string]
        $ids = @($GroupId | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        if ($ids.Count -eq 1) {
            $clauses.Add(('id EQ "{0}"' -f $ids[0]))
        } elseif ($ids.Count -gt 1) {
            $clauses.Add(('id IN {0}' -f ($ids -join ',')))
        }
        if (-not [string]::IsNullOrWhiteSpace($Filter)) { $clauses.Add($Filter.Trim()) }
        if ($clauses.Count -eq 0) {
            $PSCmdlet.ThrowTerminatingError((New-Object System.Management.Automation.ErrorRecord((New-Object System.ArgumentException('Remove-EPMEndpointGroup requires -GroupId or a non-empty -Filter. An empty filter is not sent.')), 'EPMEmptyFilter', 'InvalidArgument', $SetId)))
        }
        $deleteFilter = $clauses -join ' AND '

        $target = 'Set {0}, groups matching {1}' -f $SetId, $deleteFilter
        if (-not $PSCmdlet.ShouldProcess($target, 'Delete endpoint groups')) { return }

        $response = Invoke-EPMRestMethod -Method POST -Path ('Sets/{0}/Endpoints/groups/delete' -f $SetId) -Body @{ filter = $deleteFilter }
        $applied = @($response.appliedIds | Where-Object { $_ })
        if ($applied.Count -eq 0) {
            Write-Warning ('No endpoint groups matched {0} in set {1}.' -f $deleteFilter, $SetId)
        }
        $result = [pscustomobject]@{
            SetId            = $SetId
            Filter           = $deleteFilter
            AppliedIds       = $applied
            AttachedPolicies = $response.attachedPolicies
        }
        $result.PSObject.TypeNames.Insert(0, 'psEPM.EndpointGroupRemoval')
        $result
    }
}
