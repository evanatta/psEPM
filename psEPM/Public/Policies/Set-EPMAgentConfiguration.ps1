function Set-EPMAgentConfiguration {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium', DefaultParameterSetName = 'Merge')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$SetId,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('PolicyId')]
        [ValidateNotNullOrEmpty()]
        [string]$AgentConfigurationId,

        [Parameter(Mandatory = $true, ParameterSetName = 'FromObject')]
        [ValidateNotNull()]
        [object]$Policy,

        [Parameter(Mandatory = $false, ParameterSetName = 'Merge')]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $false, ParameterSetName = 'Merge')]
        [AllowEmptyString()]
        [string]$Description
    )

    process {
        $path = 'Sets/{0}/Policies/AgentConfiguration/{1}' -f $SetId, $AgentConfigurationId
        $changes = @()
        if ($PSCmdlet.ParameterSetName -eq 'FromObject') {
            try {
                $converted = ConvertTo-EPMAgentConfigurationBody -Policy $Policy -Id $AgentConfigurationId
            } catch {
                $PSCmdlet.ThrowTerminatingError((New-Object System.Management.Automation.ErrorRecord($_.Exception, 'EPMInvalidPolicy', 'InvalidArgument', $Policy)))
            }
            $body = $converted.Json
            $action = 'Replace agent configuration'
        } else {
            foreach ($field in 'Name', 'Description') {
                if ($PSBoundParameters.ContainsKey($field)) { $changes += $field }
            }
            if ($changes.Count -eq 0) {
                $PSCmdlet.ThrowTerminatingError((New-Object System.Management.Automation.ErrorRecord((New-Object System.ArgumentException('Specify -Name, -Description, or -Policy.')), 'EPMNoChange', 'InvalidArgument', $AgentConfigurationId)))
            }
            if ($PSBoundParameters.ContainsKey('Name') -and [string]::IsNullOrWhiteSpace($Name)) {
                $PSCmdlet.ThrowTerminatingError((New-Object System.Management.Automation.ErrorRecord((New-Object System.ArgumentException('-Name cannot be blank.')), 'EPMBlankName', 'InvalidArgument', $Name)))
            }
            $action = 'Update agent configuration ({0})' -f ($changes -join ', ')
        }
        $target = 'Set {0}, agent configuration {1}' -f $SetId, $AgentConfigurationId
        if (-not $PSCmdlet.ShouldProcess($target, $action)) { return }

        if ($PSCmdlet.ParameterSetName -eq 'Merge') {
            $current = Invoke-EPMRestMethod -Method GET -Path $path
            $definition = $current
            if ($null -ne $current.PSObject.Properties['Policy'] -and $null -eq $current.PSObject.Properties['PolicyType']) { $definition = $current.Policy }
            foreach ($field in $changes) {
                Add-EPMPropertyValue -InputObject $definition -Name $field -Value $PSBoundParameters[$field]
            }
            Add-EPMPropertyValue -InputObject $definition -Name Id -Value $AgentConfigurationId
            $body = ConvertTo-EPMJson -InputObject $definition -ExcludeProperty 'SetId', 'PolicyId', 'AgentConfigurationId'
        }

        $item = Invoke-EPMRestMethod -Method PUT -Path $path -Body $body
        Add-EPMAgentConfigurationInfo -InputObject $item -SetId $SetId -DefaultId $AgentConfigurationId
    }
}
