function Add-EPMPropertyValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$InputObject,

        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [AllowEmptyString()]
        [object]$Value
    )

    $property = $InputObject.PSObject.Properties[$Name]
    if ($null -ne $property -and $property.MemberType -eq 'NoteProperty') {
        $property.Value = $Value
    } else {
        $InputObject | Add-Member -MemberType NoteProperty -Name $Name -Value $Value -Force
    }
}
