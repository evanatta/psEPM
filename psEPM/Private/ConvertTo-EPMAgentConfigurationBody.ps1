function ConvertTo-EPMAgentConfigurationBody {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Policy,

        [Parameter(Mandatory = $true)]
        [string]$Id
    )

    $json = ConvertTo-EPMPolicyBody -Policy $Policy
    try {
        $definition = $json | ConvertFrom-Json -ErrorAction Stop
    } catch {
        throw (New-Object System.ArgumentException('-Policy is not valid JSON.'))
    }
    if ($null -eq $definition -or $definition -isnot [System.Management.Automation.PSCustomObject]) {
        throw (New-Object System.ArgumentException('-Policy must be a single agent configuration object.'))
    }
    if ($null -ne $definition.PSObject.Properties['Policy'] -and $null -eq $definition.PSObject.Properties['PolicyType']) { $definition = $definition.Policy }
    Add-EPMPropertyValue -InputObject $definition -Name Id -Value $Id
    [pscustomobject]@{
        Name = [string]$definition.Name
        Json = ConvertTo-EPMJson -InputObject $definition -ExcludeProperty 'SetId', 'PolicyId', 'AgentConfigurationId'
    }
}
