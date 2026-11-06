function Remove-EPMAgentConfiguration {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$SetId,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('PolicyId')]
        [ValidateNotNullOrEmpty()]
        [string[]]$AgentConfigurationId,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [Alias('PolicyName')]
        [string]$Name
    )

    process {
        foreach ($id in $AgentConfigurationId) {
            if ([string]::IsNullOrWhiteSpace($id)) {
                $PSCmdlet.WriteError((New-Object System.Management.Automation.ErrorRecord((New-Object System.ArgumentException('An agent configuration ID cannot be blank.')), 'EPMBlankId', 'InvalidArgument', $id)))
                continue
            }
            if ($id -eq $SetId) {
                $PSCmdlet.WriteError((New-Object System.Management.Automation.ErrorRecord((New-Object System.InvalidOperationException(('Agent configuration {0} is the set''s General configuration, which cannot be deleted.' -f $id))), 'EPMGeneralConfiguration', 'InvalidOperation', $id)))
                continue
            }
            $target = 'Set {0}, agent configuration {1}' -f $SetId, $id
            if ($Name -and $AgentConfigurationId.Count -eq 1) { $target = '{0} ("{1}")' -f $target, $Name }
            if (-not $PSCmdlet.ShouldProcess($target, 'Delete agent configuration')) { continue }
            $null = Invoke-EPMRestMethod -Method DELETE -Path ('Sets/{0}/Policies/AgentConfiguration/{1}' -f $SetId, $id)
            $removedName = $null
            if ($AgentConfigurationId.Count -eq 1 -and $Name) { $removedName = $Name }
            $result = [pscustomobject]@{ SetId = $SetId; AgentConfigurationId = $id; Name = $removedName }
            $result.PSObject.TypeNames.Insert(0, 'psEPM.AgentConfigurationRemoval')
            $result
        }
    }
}
