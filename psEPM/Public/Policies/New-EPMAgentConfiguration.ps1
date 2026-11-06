function New-EPMAgentConfiguration {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium', DefaultParameterSetName = 'FromSource')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$SetId,

        [Parameter(Mandatory = $true, ParameterSetName = 'FromSource')]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $true, ParameterSetName = 'FromSource')]
        [ValidatePattern('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')]
        [string]$EndpointId,

        [Parameter(Mandatory = $false, ParameterSetName = 'FromSource')]
        [AllowEmptyString()]
        [string]$Description,

        [Parameter(Mandatory = $false, ParameterSetName = 'FromSource')]
        [ValidateNotNullOrEmpty()]
        [string]$SourceAgentConfigurationId,

        [Parameter(Mandatory = $true, ParameterSetName = 'FromObject')]
        [ValidateNotNull()]
        [object]$Policy
    )

    process {
        $zeroId = '00000000-0000-0000-0000-000000000000'
        if ($PSCmdlet.ParameterSetName -eq 'FromSource') {
            if ([string]::IsNullOrWhiteSpace($Name)) {
                $PSCmdlet.ThrowTerminatingError((New-Object System.Management.Automation.ErrorRecord((New-Object System.ArgumentException('-Name cannot be blank.')), 'EPMBlankName', 'InvalidArgument', $Name)))
            }
            if ($EndpointId -eq $zeroId) {
                $PSCmdlet.ThrowTerminatingError((New-Object System.Management.Automation.ErrorRecord((New-Object System.ArgumentException('-EndpointId must be the ID of an existing computer in the set.')), 'EPMInvalidEndpointId', 'InvalidArgument', $EndpointId)))
            }
            $sourceId = $SetId
            if ($PSBoundParameters.ContainsKey('SourceAgentConfigurationId')) { $sourceId = $SourceAgentConfigurationId }
            $label = $Name
            $target = 'Set {0}, agent configuration "{1}" for endpoint {2}' -f $SetId, $Name, $EndpointId
        } else {
            try {
                $converted = ConvertTo-EPMAgentConfigurationBody -Policy $Policy -Id $zeroId
            } catch {
                $PSCmdlet.ThrowTerminatingError((New-Object System.Management.Automation.ErrorRecord($_.Exception, 'EPMInvalidPolicy', 'InvalidArgument', $Policy)))
            }
            $body = $converted.Json
            $label = $converted.Name
            if ([string]::IsNullOrEmpty($label)) { $label = '(agent configuration definition)' }
            $target = 'Set {0}, agent configuration "{1}"' -f $SetId, $label
        }

        if (-not $PSCmdlet.ShouldProcess($target, 'Create agent configuration')) { return }

        if ($PSCmdlet.ParameterSetName -eq 'FromSource') {
            $source = Invoke-EPMRestMethod -Method GET -Path ('Sets/{0}/Policies/AgentConfiguration/{1}' -f $SetId, $sourceId)
            $definition = $source
            if ($null -ne $source.PSObject.Properties['Policy'] -and $null -eq $source.PSObject.Properties['PolicyType']) { $definition = $source.Policy }
            Add-EPMPropertyValue -InputObject $definition -Name Id -Value $zeroId
            Add-EPMPropertyValue -InputObject $definition -Name Name -Value $Name
            if ($PSBoundParameters.ContainsKey('Description')) { Add-EPMPropertyValue -InputObject $definition -Name Description -Value $Description }
            Add-EPMPropertyValue -InputObject $definition -Name IsAppliedToAllComputers -Value $false
            $executor = [ordered]@{ Id = $EndpointId; IsIncluded = $true; ExecutorType = 1 }
            Add-EPMPropertyValue -InputObject $definition -Name Executors -Value @(, $executor)
            $body = ConvertTo-EPMJson -InputObject $definition -ExcludeProperty 'SetId', 'PolicyId', 'AgentConfigurationId'
        }

        $item = Invoke-EPMRestMethod -Method POST -Path ('Sets/{0}/Policies/AgentConfiguration' -f $SetId) -Body $body
        Add-EPMAgentConfigurationInfo -InputObject $item -SetId $SetId -DefaultId ([string]$EndpointId)
    }
}
