function ConvertTo-EPMPackage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$InputObject,

        [Parameter(Mandatory = $true)]
        [string]$SetId,

        [Parameter(Mandatory = $true)]
        [string]$TypeName
    )

    $version = $null
    $release = $InputObject.releaseVersion
    if ($release -is [string]) {
        $version = $release
    } elseif ($null -ne $release) {
        $version = '{0}.{1}.{2}.{3}' -f $release._major, $release._minor, $release._build, $release._revision
    }

    $InputObject | Add-Member -MemberType NoteProperty -Name SetId -Value $SetId -Force
    $InputObject | Add-Member -MemberType NoteProperty -Name PackageId -Value $InputObject.id -Force
    $InputObject | Add-Member -MemberType NoteProperty -Name Version -Value $version -Force
    $InputObject.PSObject.TypeNames.Insert(0, $TypeName)
    $InputObject
}
