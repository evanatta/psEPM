function Set-EPMPolicyElevation {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$SetId,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [ValidatePattern('^[^"]+$')]
        [string]$AggregatedBy,

        [Parameter(Mandatory = $false)]
        [string]$Filter,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Approve', 'Reject')]
        [string]$Elevation,

        [Parameter(Mandatory = $false)]
        [switch]$SendEmail
    )

    process {
        $clauses = New-Object System.Collections.Generic.List[string]
        if (-not [string]::IsNullOrWhiteSpace($AggregatedBy)) { $clauses.Add(('aggregatedBy EQ "{0}"' -f $AggregatedBy.Trim())) }
        if (-not [string]::IsNullOrWhiteSpace($Filter)) { $clauses.Add($Filter.Trim()) }
        if ($clauses.Count -eq 0) {
            $PSCmdlet.ThrowTerminatingError((New-Object System.Management.Automation.ErrorRecord((New-Object System.ArgumentException('Set-EPMPolicyElevation requires -AggregatedBy or a non-empty -Filter. An empty filter is not sent.')), 'EPMEmptyFilter', 'InvalidArgument', $SetId)))
        }
        $elevationFilter = $clauses -join ' AND '

        if ($Elevation -eq 'Approve') {
            $method = 'POST'
            $value = 1
        } else {
            $method = 'DELETE'
            $value = 2
        }
        $body = [ordered]@{ SendEmail = [bool]$SendEmail; Filter = $elevationFilter; Elevation = $value }
        $json = ConvertTo-EPMJson -InputObject $body

        $target = 'Set {0}, elevation requests matching {1}' -f $SetId, $elevationFilter
        $action = '{0} temporary elevation{1}' -f $Elevation, $(if ($SendEmail) { ' and email the requestor' } else { '' })
        if (-not $PSCmdlet.ShouldProcess($target, $action)) { return }

        $response = Invoke-EPMRestMethod -Method $method -Path ('Sets/{0}/Policies/Server/Elevate' -f $SetId) -Body $json
        if ($null -ne $response -and $response -isnot [string]) {
            if ($null -eq $response.PSObject.Properties['SetId']) { $response | Add-Member -MemberType NoteProperty -Name SetId -Value $SetId }
            $response.PSObject.TypeNames.Insert(0, 'psEPM.PolicyElevation')
            return $response
        }
        $result = [pscustomobject]@{
            SetId     = $SetId
            Elevation = $Elevation
            Filter    = $elevationFilter
        }
        $result.PSObject.TypeNames.Insert(0, 'psEPM.PolicyElevation')
        $result
    }
}
