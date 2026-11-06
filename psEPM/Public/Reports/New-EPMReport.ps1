function New-EPMReport {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$SetId,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidatePattern('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')]
        [string]$ReportId,

        [Parameter(Mandatory = $false)]
        [ValidateSet('JSON', 'CSV')]
        [string]$Format = 'JSON',

        [Parameter(Mandatory = $false)]
        [string]$OutFile
    )

    process {
        $formatValue = $Format.ToUpperInvariant()
        $body = @{ reportId = $ReportId; format = $formatValue }
        $target = 'Set {0}, report {1}' -f $SetId, $ReportId
        if (-not $PSCmdlet.ShouldProcess($target, ('Generate report ({0})' -f $formatValue))) { return }

        $response = Invoke-EPMRestMethod -Method POST -Path ('Sets/{0}/Reports' -f $SetId) -Body $body -IncludeResponseHeader

        $bytes = $null
        if ($response.Content -is [byte[]]) {
            $bytes = [byte[]]$response.Content
            $text = [System.Text.Encoding]::UTF8.GetString($bytes)
        } elseif ($response.Content -is [string]) {
            $text = [string]$response.Content
        } else {
            $text = $null
        }
        if ($text -and $text.Length -gt 0 -and $text[0] -eq [char]0xFEFF) { $text = $text.Substring(1) }

        $fileName = $null
        if ($response.Headers) {
            foreach ($key in @($response.Headers.Keys)) {
                if ($key -eq 'Content-Disposition') {
                    $disposition = @($response.Headers[$key]) -join ''
                    if ($disposition -match 'filename\*?=["'']?([^"'';]+)') { $fileName = $Matches[1] }
                }
            }
        }

        $content = $response.Content
        if ($null -ne $text) {
            $content = $text
            if ($formatValue -eq 'JSON' -and $text.Trim().Length -gt 0) {
                try { $content = $text | ConvertFrom-Json -ErrorAction Stop } catch { $content = $text }
            }
        }

        $path = $null
        if ($OutFile) {
            $path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutFile)
            if ($null -ne $bytes) {
                [System.IO.File]::WriteAllBytes($path, $bytes)
            } elseif ($null -ne $text) {
                [System.IO.File]::WriteAllText($path, $text, (New-Object System.Text.UTF8Encoding($false)))
            } else {
                [System.IO.File]::WriteAllText($path, (ConvertTo-Json -InputObject $response.Content -Depth 20), (New-Object System.Text.UTF8Encoding($false)))
            }
        }

        $item = [pscustomobject]@{
            SetId    = $SetId
            ReportId = $ReportId
            Format   = $formatValue
            FileName = $fileName
            Content  = $content
            Path     = $path
        }
        $item.PSObject.TypeNames.Insert(0, 'psEPM.Report')
        $item
    }
}
