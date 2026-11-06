function Get-EPMTokenExpiry {
    [CmdletBinding()]
    [OutputType([datetime])]
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [AllowEmptyString()]
        [string]$Token
    )

    if ([string]::IsNullOrEmpty($Token)) { return $null }
    $parts = $Token.Split('.')
    if ($parts.Count -ne 3 -or [string]::IsNullOrEmpty($parts[1])) { return $null }
    $payload = $parts[1].Replace('-', '+').Replace('_', '/')
    $remainder = $payload.Length % 4
    if ($remainder -eq 1) { return $null }
    if ($remainder -eq 2) { $payload += '==' }
    if ($remainder -eq 3) { $payload += '=' }
    try {
        $json = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($payload))
        $claims = $json | ConvertFrom-Json -ErrorAction Stop
    } catch {
        return $null
    }
    $json = $null
    if ($null -eq $claims -or $claims -isnot [System.Management.Automation.PSCustomObject] -or $null -eq $claims.PSObject.Properties['exp']) { return $null }
    $seconds = 0.0
    if (-not [double]::TryParse([string]$claims.exp, [System.Globalization.NumberStyles]::Float, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$seconds)) { return $null }
    if ($seconds -le 0 -or $seconds -gt 253402300799) { return $null }
    (New-Object System.DateTime(1970, 1, 1, 0, 0, 0, ([System.DateTimeKind]::Utc))).AddSeconds($seconds)
}
