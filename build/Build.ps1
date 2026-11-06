[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,

    [Parameter(Mandatory = $false)]
    [switch]$Publish,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$Repository = 'PSGallery'
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$moduleName = 'psEPM'
$sourceRoot = Join-Path $repoRoot $moduleName

if ($Publish -and [string]::IsNullOrEmpty($env:PSGALLERY_API_KEY)) {
    throw '-Publish needs a NuGet API key in the PSGALLERY_API_KEY environment variable. Nothing was built or published.'
}

if ([string]::IsNullOrEmpty($OutputPath)) { $OutputPath = Join-Path $repoRoot 'output' }
$OutputPath = [System.IO.Path]::GetFullPath($OutputPath)
$fullSource = [System.IO.Path]::GetFullPath($sourceRoot).TrimEnd([System.IO.Path]::DirectorySeparatorChar)
$fullRepo = [System.IO.Path]::GetFullPath($repoRoot).TrimEnd([System.IO.Path]::DirectorySeparatorChar)
if ($OutputPath.TrimEnd([System.IO.Path]::DirectorySeparatorChar) -eq $fullRepo -or $OutputPath.StartsWith($fullSource, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw 'OutputPath must not be the repository root or inside the module source folder.'
}

$manifestPath = Join-Path $sourceRoot ('{0}.psd1' -f $moduleName)
$manifestData = Import-PowerShellDataFile -Path $manifestPath
$version = [string]$manifestData.ModuleVersion
$moduleOut = Join-Path $OutputPath $moduleName
$packageRoot = Join-Path $moduleOut $version

if (Test-Path -LiteralPath $moduleOut) { Remove-Item -LiteralPath $moduleOut -Recurse -Force }
$null = New-Item -ItemType Directory -Path $packageRoot -Force

$files = @(
    ('{0}.psd1' -f $moduleName),
    ('{0}.psm1' -f $moduleName),
    ('{0}.Format.ps1xml' -f $moduleName)
)
foreach ($file in $files) {
    Copy-Item -LiteralPath (Join-Path $sourceRoot $file) -Destination $packageRoot
}
foreach ($folder in 'Public', 'Private') {
    $sourceFolder = Join-Path $sourceRoot $folder
    Get-ChildItem -LiteralPath $sourceFolder -Recurse -File -Filter '*.ps1' | Sort-Object FullName | ForEach-Object {
        $relative = $_.FullName.Substring($sourceRoot.Length).TrimStart([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
        $target = Join-Path $packageRoot $relative
        $targetFolder = Split-Path -Parent $target
        if (-not (Test-Path -LiteralPath $targetFolder)) { $null = New-Item -ItemType Directory -Path $targetFolder -Force }
        Copy-Item -LiteralPath $_.FullName -Destination $target
    }
}
Copy-Item -LiteralPath (Join-Path $repoRoot 'LICENSE') -Destination $packageRoot

$blocked = @(Get-ChildItem -LiteralPath $packageRoot -Recurse -Force | Where-Object { $_.Name -like '*.token' -or $_.Name -like '*.secret' -or $_.Name -eq '.env' -or $_.Name -eq 'Tests' -or $_.Name -like '*.Tests.ps1' })
if ($blocked.Count -gt 0) {
    throw ('The package contains files that must not be shipped: {0}' -f (($blocked | ForEach-Object { $_.Name }) -join ', '))
}

$packagedManifest = Join-Path $packageRoot ('{0}.psd1' -f $moduleName)
$moduleInfo = Test-ModuleManifest -Path $packagedManifest -ErrorAction Stop
if ([string]$moduleInfo.Version -ne $version) {
    throw ('Packaged manifest version {0} does not match {1}.' -f $moduleInfo.Version, $version)
}

$fileCount = @(Get-ChildItem -LiteralPath $packageRoot -Recurse -File).Count
Write-Verbose ('Packaged {0} {1} to {2} ({3} files).' -f $moduleName, $version, $packageRoot, $fileCount)

if ($Publish) {
    if ($PSCmdlet.ShouldProcess(('{0} {1} to {2}' -f $moduleName, $version, $Repository), 'Publish module')) {
        Publish-Module -Path $packageRoot -NuGetApiKey $env:PSGALLERY_API_KEY -Repository $Repository -ErrorAction Stop
        Write-Verbose ('Published {0} {1} to {2}.' -f $moduleName, $version, $Repository)
    }
}

[pscustomobject]@{
    Name      = $moduleName
    Version   = $version
    Path      = $packageRoot
    FileCount = $fileCount
    Published = [bool]($Publish -and -not $WhatIfPreference)
}
