function New-EPMPolicy {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium', DefaultParameterSetName = 'FileName')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$SetId,

        [Parameter(Mandatory = $true, ParameterSetName = 'FromObject')]
        [ValidateNotNull()]
        [object]$Policy,

        [Parameter(Mandatory = $true, ParameterSetName = 'FileName')]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $true, ParameterSetName = 'FileName')]
        [ValidateNotNullOrEmpty()]
        [string]$FileName,

        [Parameter(Mandatory = $false, ParameterSetName = 'FileName')]
        [string]$Description,

        [Parameter(Mandatory = $false, ParameterSetName = 'FileName')]
        [int]$PolicyType = 11,

        [Parameter(Mandatory = $false, ParameterSetName = 'FileName')]
        [int]$Action = 1,

        [Parameter(Mandatory = $false, ParameterSetName = 'FileName')]
        [bool]$Audit = $false,

        [Parameter(Mandatory = $false, ParameterSetName = 'FileName')]
        [bool]$IsActive = $false,

        [Parameter(Mandatory = $false, ParameterSetName = 'FileName')]
        [bool]$IsAppliedToAllComputers = $true
    )

    process {
        if ($PSCmdlet.ParameterSetName -eq 'FileName') {
            $pattern = [ordered]@{
                '@type'       = 'FileName'
                isEmpty       = $false
                compareAs     = 0
                caseSensitive = $false
                content       = $FileName
            }
            $application = [ordered]@{
                applicationType = 3
                displayName     = $FileName
                patterns        = [ordered]@{ FILE_NAME = $pattern }
            }
            $definition = [ordered]@{
                Name                    = $Name
                PolicyType              = $PolicyType
                Action                  = $Action
                Description             = $Description
                IsActive                = $IsActive
                IsAppliedToAllComputers = $IsAppliedToAllComputers
                Audit                   = $Audit
                Applications            = @(, $application)
            }
            $body = ConvertTo-EPMJson -InputObject $definition
            $label = $Name
        } else {
            $body = ConvertTo-EPMPolicyBody -Policy $Policy
            $label = '(policy definition)'
            try {
                $parsed = $body | ConvertFrom-Json -ErrorAction Stop
                if ($parsed.Name) { $label = [string]$parsed.Name }
            } catch {
                $PSCmdlet.ThrowTerminatingError((New-Object System.Management.Automation.ErrorRecord((New-Object System.ArgumentException('-Policy is not valid JSON.')), 'EPMInvalidPolicy', 'InvalidArgument', $Policy)))
            }
        }

        $target = 'Set {0}, policy "{1}"' -f $SetId, $label
        if (-not $PSCmdlet.ShouldProcess($target, 'Create policy')) { return }

        $item = Invoke-EPMRestMethod -Method POST -Path ('Sets/{0}/Policies/Server' -f $SetId) -Body $body
        $item | Add-Member -MemberType NoteProperty -Name SetId -Value $SetId -Force
        $item | Add-Member -MemberType NoteProperty -Name PolicyId -Value $item.Id -Force
        $item.PSObject.TypeNames.Insert(0, 'psEPM.PolicyDefinition')
        $item
    }
}
