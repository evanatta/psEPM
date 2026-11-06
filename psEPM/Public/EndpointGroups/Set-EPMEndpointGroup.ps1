function Set-EPMEndpointGroup {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$SetId,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$GroupId,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [string]$Description,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$Filter
    )

    process {
        $target = 'Set {0}, group {1}' -f $SetId, $GroupId
        if (-not $PSCmdlet.ShouldProcess($target, 'Update endpoint group')) { return }

        $current = @(Get-EPMEndpointGroup -SetId $SetId -GroupId $GroupId -First 1)
        if ($current.Count -eq 0) {
            $PSCmdlet.ThrowTerminatingError((New-Object System.Management.Automation.ErrorRecord((New-Object System.Management.Automation.ItemNotFoundException(('Endpoint group {0} was not found in set {1}.' -f $GroupId, $SetId))), 'EPMGroupNotFound', 'ObjectNotFound', $GroupId)))
        }
        $group = $current[0]
        if ($PSBoundParameters.ContainsKey('Filter') -and $group.type -ne 'Dynamic') {
            $PSCmdlet.ThrowTerminatingError((New-Object System.Management.Automation.ErrorRecord((New-Object System.ArgumentException('-Filter applies only to Dynamic groups.')), 'EPMFilterNotAllowed', 'InvalidArgument', $Filter)))
        }

        $body = @{ id = $GroupId; type = $group.type; name = $group.name }
        if ($PSBoundParameters.ContainsKey('Name')) { $body.name = $Name }
        $newDescription = $group.description
        if ($PSBoundParameters.ContainsKey('Description')) { $newDescription = $Description }
        if ($newDescription) { $body.description = $newDescription }
        if ($group.type -eq 'Dynamic') {
            $body.filter = $group.filter
            if ($PSBoundParameters.ContainsKey('Filter')) { $body.filter = $Filter }
        }

        $item = Invoke-EPMRestMethod -Method PUT -Path ('Sets/{0}/Endpoints/groups' -f $SetId) -Body $body
        $item | Add-Member -MemberType NoteProperty -Name SetId -Value $SetId -Force
        $item | Add-Member -MemberType NoteProperty -Name GroupId -Value $item.id -Force
        $item.PSObject.TypeNames.Insert(0, 'psEPM.EndpointGroup')
        $item
    }
}
