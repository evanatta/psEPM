function Get-EPMPackageConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$SetId,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$PackageId,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('packageOS')]
        [ValidateSet('Windows', 'MacOS', 'Linux')]
        [string]$Platform,

        [Parameter(Mandatory = $false)]
        [switch]$IncludePolicies,

        [Parameter(Mandatory = $false)]
        [string]$OutFile
    )

    process {
        $body = @{
            includePolicies = [bool]$IncludePolicies
            platform        = $Platform.ToLowerInvariant()
            packageId       = $PackageId
        }
        $response = Invoke-EPMRestMethod -Method POST -Path ('Sets/{0}/packages/configuration' -f $SetId) -Body $body -IncludeResponseHeader

        $content = [string]$response.Content
        $installationKey = $null
        if ($response.Headers) {
            foreach ($key in @($response.Headers.Keys)) {
                if ($key -eq 'installationKey') {
                    $installationKey = @($response.Headers[$key]) -join ''
                }
            }
        }

        $path = $null
        if ($OutFile) {
            $path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutFile)
            [System.IO.File]::WriteAllText($path, $content, (New-Object System.Text.UTF8Encoding($false)))
        }

        $item = [pscustomobject]@{
            SetId           = $SetId
            PackageId       = $PackageId
            Platform        = $Platform
            InstallationKey = $installationKey
            Configuration   = ($content | ConvertFrom-Json)
            Path            = $path
        }
        $item.PSObject.TypeNames.Insert(0, 'psEPM.PackageConfiguration')
        $item
    }
}
