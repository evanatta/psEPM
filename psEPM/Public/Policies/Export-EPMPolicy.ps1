function Export-EPMPolicy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$SetId,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Computer', 'User', 'All')]
        [string]$GroupType = 'All',

        [Parameter(Mandatory = $false)]
        [string]$OutFile
    )

    process {
        $typeMap = @{ Computer = 0; User = 1; All = 3 }
        $body = @{ ServerPolicyGroupType = $typeMap[$GroupType] }
        $response = Invoke-EPMRestMethod -Method POST -Path ('Sets/{0}/Policies/Server/Export' -f $SetId) -Body $body -IncludeResponseHeader

        $bytes = $null
        if ($response.Content -is [byte[]]) {
            $bytes = [byte[]]$response.Content
            $content = [System.Text.Encoding]::UTF8.GetString($bytes)
        } else {
            $content = [string]$response.Content
        }
        if ($content.Length -gt 0 -and $content[0] -eq [char]0xFEFF) { $content = $content.Substring(1) }

        $fileName = $null
        if ($response.Headers) {
            foreach ($key in @($response.Headers.Keys)) {
                if ($key -eq 'Content-Disposition') {
                    $disposition = @($response.Headers[$key]) -join ''
                    if ($disposition -match 'filename\*?=["'']?([^"'';]+)') { $fileName = $Matches[1] }
                }
            }
        }

        $path = $null
        if ($OutFile) {
            $path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutFile)
            if ($null -ne $bytes) {
                [System.IO.File]::WriteAllBytes($path, $bytes)
            } else {
                [System.IO.File]::WriteAllText($path, $content, (New-Object System.Text.UTF8Encoding($false)))
            }
        }

        $item = [pscustomobject]@{
            SetId     = $SetId
            GroupType = $GroupType
            FileName  = $fileName
            Export    = ($content | ConvertFrom-Json)
            Path      = $path
        }
        $item.PSObject.TypeNames.Insert(0, 'psEPM.PolicyExport')
        $item
    }
}
