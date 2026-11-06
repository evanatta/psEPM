function Get-EPMPackageUrl {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$SetId,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$PackageId
    )

    process {
        $url = Invoke-EPMRestMethod -Method GET -Path ('Sets/{0}/packages/{1}/Url' -f $SetId, $PackageId)
        $item = [pscustomobject]@{
            SetId     = $SetId
            PackageId = $PackageId
            Url       = [string]$url
        }
        $item.PSObject.TypeNames.Insert(0, 'psEPM.PackageUrl')
        $item
    }
}
