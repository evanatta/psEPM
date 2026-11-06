function Invoke-EPMRestMethod {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('GET', 'POST', 'PUT', 'PATCH', 'DELETE')]
        [string]$Method,

        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [object]$Body,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeResponseHeader,

        [Parameter(Mandatory = $false)]
        [int]$MaxRetry = 5,

        [Parameter(Mandatory = $false)]
        [int]$RetryDelaySeconds = 2
    )

    Assert-EPMSession

    $uri = '{0}/{1}' -f $script:EPMSession.ApiURI, $Path.TrimStart('/')
    $request = @{
        Uri         = $uri
        Method      = $Method
        Headers     = @{ Authorization = 'Bearer {0}' -f $script:EPMSession.Token }
        ContentType = 'application/json'
        ErrorAction = 'Stop'
    }
    if ($PSBoundParameters.ContainsKey('Body')) {
        if ($Body -is [string]) {
            $request.Body = $Body
        } else {
            $request.Body = ConvertTo-Json -InputObject $Body -Depth 20 -Compress
        }
    }

    $attempt = 0
    while ($true) {
        try {
            if ($IncludeResponseHeader) {
                $response = Invoke-WebRequest @request -UseBasicParsing
                $result = [pscustomobject]@{
                    Content = $response.Content
                    Headers = $response.Headers
                }
            } else {
                $result = Invoke-RestMethod @request
            }
            $exported = $MyInvocation.MyCommand.Module.ExportedFunctions.Keys
            $caller = Get-PSCallStack | Where-Object { $exported -contains $_.Command } | Select-Object -First 1
            if ($caller) { $script:EPMSession.LastCommand = $caller.Command }
            $script:EPMSession.LastCommandTime = Get-Date
            return $result
        } catch {
            $detail = Get-EPMErrorDetail -ErrorRecord $_
            $script:EPMSession.LastError = $detail
            $throttled = ($detail.StatusCode -eq 429) -or ($detail.ErrorCode -eq 'EPM050004E')
            if ($throttled -and $attempt -lt $MaxRetry) {
                $attempt++
                $delay = $RetryDelaySeconds * [math]::Pow(2, $attempt - 1)
                Write-Verbose ('Throttled. Retry {0} of {1} in {2} seconds.' -f $attempt, $MaxRetry, $delay)
                Start-Sleep -Seconds $delay
                continue
            }
            $text = 'EPM API {0} {1} failed. HTTP {2} {3} {4}' -f $Method, $Path, $detail.StatusCode, $detail.ErrorCode, $detail.Message
            $exception = New-Object System.Exception($text.Trim())
            $record = New-Object System.Management.Automation.ErrorRecord($exception, ('EPM' + [string]$detail.ErrorCode), 'InvalidOperation', $uri)
            $PSCmdlet.ThrowTerminatingError($record)
        }
    }
}
