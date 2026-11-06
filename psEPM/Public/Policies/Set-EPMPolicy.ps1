function Set-EPMPolicy {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium', DefaultParameterSetName = 'Merge')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$SetId,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$PolicyId,

        [Parameter(Mandatory = $true, ParameterSetName = 'FromObject')]
        [ValidateNotNull()]
        [object]$Policy,

        [Parameter(Mandatory = $false, ParameterSetName = 'Merge')]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $false, ParameterSetName = 'Merge')]
        [AllowEmptyString()]
        [string]$Description,

        [Parameter(Mandatory = $false, ParameterSetName = 'Merge')]
        [bool]$IsActive,

        [Parameter(Mandatory = $false, ParameterSetName = 'Merge')]
        [bool]$Audit
    )

    process {
        if ($PSCmdlet.ParameterSetName -eq 'FromObject') {
            $body = ConvertTo-EPMPolicyBody -Policy $Policy
            try {
                $null = $body | ConvertFrom-Json -ErrorAction Stop
            } catch {
                $PSCmdlet.ThrowTerminatingError((New-Object System.Management.Automation.ErrorRecord((New-Object System.ArgumentException('-Policy is not valid JSON.')), 'EPMInvalidPolicy', 'InvalidArgument', $Policy)))
            }
        }

        $changes = @()
        foreach ($field in 'Name', 'Description', 'IsActive', 'Audit') {
            if ($PSBoundParameters.ContainsKey($field)) { $changes += $field }
        }
        $action = 'Replace policy'
        if ($PSCmdlet.ParameterSetName -eq 'Merge') { $action = 'Update policy ({0})' -f ($changes -join ', ') }
        $target = 'Set {0}, policy {1}' -f $SetId, $PolicyId
        if (-not $PSCmdlet.ShouldProcess($target, $action)) { return }

        if ($PSCmdlet.ParameterSetName -eq 'Merge') {
            $current = Invoke-EPMRestMethod -Method GET -Path ('Sets/{0}/Policies/Server/{1}' -f $SetId, $PolicyId)
            $definition = $current
            if ($null -ne $current.PSObject.Properties['Policy'] -and $null -eq $current.PSObject.Properties['PolicyType']) { $definition = $current.Policy }
            foreach ($field in $changes) {
                $definition | Add-Member -MemberType NoteProperty -Name $field -Value $PSBoundParameters[$field] -Force
            }
            $definition | Add-Member -MemberType NoteProperty -Name Id -Value $PolicyId -Force
            $body = ConvertTo-EPMJson -InputObject $definition -ExcludeProperty 'SetId', 'PolicyId'
        }

        $item = Invoke-EPMRestMethod -Method PUT -Path ('Sets/{0}/Policies/Server/{1}' -f $SetId, $PolicyId) -Body $body
        $item | Add-Member -MemberType NoteProperty -Name SetId -Value $SetId -Force
        $item | Add-Member -MemberType NoteProperty -Name PolicyId -Value $item.Id -Force
        $item.PSObject.TypeNames.Insert(0, 'psEPM.PolicyDefinition')
        $item
    }
}
