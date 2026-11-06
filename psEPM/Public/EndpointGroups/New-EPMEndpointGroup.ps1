function New-EPMEndpointGroup {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$SetId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Static', 'Dynamic')]
        [string]$Type,

        [Parameter(Mandatory = $false)]
        [string]$Description,

        [Parameter(Mandatory = $false)]
        [string]$Filter
    )

    process {
        if ($Type -eq 'Dynamic' -and [string]::IsNullOrWhiteSpace($Filter)) {
            $PSCmdlet.ThrowTerminatingError((New-Object System.Management.Automation.ErrorRecord((New-Object System.ArgumentException('A Dynamic group requires -Filter.')), 'EPMFilterRequired', 'InvalidArgument', $Filter)))
        }
        if ($Type -eq 'Static' -and -not [string]::IsNullOrWhiteSpace($Filter)) {
            $PSCmdlet.ThrowTerminatingError((New-Object System.Management.Automation.ErrorRecord((New-Object System.ArgumentException('-Filter applies only to Dynamic groups.')), 'EPMFilterNotAllowed', 'InvalidArgument', $Filter)))
        }

        $body = @{ type = $Type; name = $Name }
        if ($Description) { $body.description = $Description }
        if ($Type -eq 'Dynamic') { $body.filter = $Filter }

        $target = 'Set {0}, {1} group "{2}"' -f $SetId, $Type, $Name
        if (-not $PSCmdlet.ShouldProcess($target, 'Create endpoint group')) { return }

        $item = Invoke-EPMRestMethod -Method POST -Path ('Sets/{0}/Endpoints/Groups' -f $SetId) -Body $body
        $item | Add-Member -MemberType NoteProperty -Name SetId -Value $SetId -Force
        $item | Add-Member -MemberType NoteProperty -Name GroupId -Value $item.id -Force
        $item.PSObject.TypeNames.Insert(0, 'psEPM.EndpointGroup')
        $item
    }
}
