$functionFiles = Get-ChildItem -Path (Join-Path $PSScriptRoot 'Private'), (Join-Path $PSScriptRoot 'Public') -Recurse -Filter '*.ps1'
foreach ($file in $functionFiles) {
    . $file.FullName
}

$script:EPMSession = $null
