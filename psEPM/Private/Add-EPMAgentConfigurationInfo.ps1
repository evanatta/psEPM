function Add-EPMAgentConfigurationInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [object]$InputObject,

        [Parameter(Mandatory = $true)]
        [string]$SetId,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$DefaultId
    )

    if ($null -eq $InputObject -or $InputObject -is [string]) { return $InputObject }
    $typeName = 'psEPM.AgentConfigurationDefinition'
    $id = $null
    if ($null -ne $InputObject.PSObject.Properties['Id']) { $id = [string]$InputObject.Id }
    if ($null -ne $InputObject.PSObject.Properties['Policy'] -and $null -eq $InputObject.PSObject.Properties['PolicyType']) {
        $typeName = 'psEPM.AgentConfigurationDetail'
        if ($null -ne $InputObject.Policy -and $null -ne $InputObject.Policy.PSObject.Properties['Id']) { $id = [string]$InputObject.Policy.Id }
    }
    if ([string]::IsNullOrEmpty($id)) { $id = $DefaultId }
    $InputObject | Add-Member -MemberType NoteProperty -Name SetId -Value $SetId -Force
    $InputObject | Add-Member -MemberType NoteProperty -Name AgentConfigurationId -Value $id -Force
    $InputObject | Add-Member -MemberType NoteProperty -Name PolicyId -Value $id -Force
    $InputObject.PSObject.TypeNames.Insert(0, $typeName)
    $InputObject
}
