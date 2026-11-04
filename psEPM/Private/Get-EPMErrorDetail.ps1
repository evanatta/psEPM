function Get-EPMErrorDetail {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )

    $statusCode = $null
    if ($ErrorRecord.Exception.Response) {
        $statusCode = [int]$ErrorRecord.Exception.Response.StatusCode
    }

    $code = $null
    $message = $ErrorRecord.Exception.Message
    $raw = $null
    if ($ErrorRecord.ErrorDetails -and $ErrorRecord.ErrorDetails.Message) {
        $raw = $ErrorRecord.ErrorDetails.Message
        try {
            $parsed = $raw | ConvertFrom-Json -ErrorAction Stop
            $first = @($parsed)[0]
            if ($first.ErrorCode) { $code = $first.ErrorCode }
            if ($first.ErrorMessage) { $message = $first.ErrorMessage }
            if ($first.code) { $code = $first.code }
            if ($first.message) { $message = $first.message }
        } catch {
            $message = $raw
        }
    }

    [pscustomobject]@{
        StatusCode = $statusCode
        ErrorCode  = $code
        Message    = $message
        Raw        = $raw
    }
}
