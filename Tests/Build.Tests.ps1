BeforeAll {
    $script:RepoRoot = Split-Path -Parent $PSScriptRoot
    $script:BuildScript = Join-Path $script:RepoRoot 'build/Build.ps1'
}

Describe 'Repository files' {
    It 'has a changelog entry for the manifest version' {
        $version = (Import-PowerShellDataFile -Path (Join-Path $script:RepoRoot 'psEPM/psEPM.psd1')).ModuleVersion
        $changelog = Get-Content -Path (Join-Path $script:RepoRoot 'CHANGELOG.md') -Raw
        $changelog | Should -Match ('## {0} - \d{{4}}-\d{{2}}-\d{{2}}' -f [regex]::Escape([string]$version))
    }

    It 'has issue and pull request templates' {
        foreach ($path in '.github/ISSUE_TEMPLATE/bug_report.md', '.github/ISSUE_TEMPLATE/feature_request.md', '.github/pull_request_template.md') {
            Test-Path (Join-Path $script:RepoRoot $path) | Should -BeTrue -Because $path
        }
        Get-Content -Path (Join-Path $script:RepoRoot '.github/ISSUE_TEMPLATE/bug_report.md') -Raw | Should -Match 'Do not paste tokens'
    }

    It 'sets ProjectUri and ReleaseNotes in the manifest' {
        $data = Import-PowerShellDataFile -Path (Join-Path $script:RepoRoot 'psEPM/psEPM.psd1')
        $data.PrivateData.PSData.ProjectUri | Should -Be 'https://github.com/evanatta/psEPM'
        $data.PrivateData.PSData.ReleaseNotes | Should -BeLike '*CHANGELOG.md'
    }
}

Describe 'build/Build.ps1' {
    BeforeAll {
        $script:Out = Join-Path $TestDrive 'out'
        $script:Result = & $script:BuildScript -OutputPath $script:Out
        $script:Package = $script:Result.Path
    }

    It 'packages the module into <output>/psEPM/<version>' {
        $version = (Import-PowerShellDataFile -Path (Join-Path $script:RepoRoot 'psEPM/psEPM.psd1')).ModuleVersion
        $script:Result.Version | Should -Be $version
        $script:Result.Published | Should -BeFalse
        $script:Package | Should -Be (Join-Path (Join-Path $script:Out 'psEPM') $version)
        foreach ($name in 'psEPM.psd1', 'psEPM.psm1', 'psEPM.Format.ps1xml', 'LICENSE', 'Public', 'Private') {
            Test-Path (Join-Path $script:Package $name) | Should -BeTrue -Because $name
        }
    }

    It 'passes Test-ModuleManifest and keeps ProjectUri' {
        $info = Test-ModuleManifest -Path (Join-Path $script:Package 'psEPM.psd1') -ErrorAction Stop
        [string]$info.ProjectUri | Should -Be 'https://github.com/evanatta/psEPM'
    }

    It 'copies every module code file and nothing else' {
        $source = Join-Path $script:RepoRoot 'psEPM'
        $expected = @(Get-ChildItem -Path (Join-Path $source 'Public'), (Join-Path $source 'Private') -Recurse -File -Filter '*.ps1').Count + 4
        @(Get-ChildItem -Path $script:Package -Recurse -File).Count | Should -Be $expected
        @(Get-ChildItem -Path $script:Package -Recurse -Force | Where-Object { $_.Name -in 'Tests', '.git', '.github', 'docs', 'build' -or $_.Name -like '*.Tests.ps1' -or $_.Name -like '*.token' }).Count | Should -Be 0
    }

    It 'replaces the previous output cleanly' {
        $stale = Join-Path $script:Package 'stale.txt'
        Set-Content -Path $stale -Value 'x'
        & $script:BuildScript -OutputPath $script:Out | Out-Null
        Test-Path $stale | Should -BeFalse
    }

    It 'refuses an output path inside the module source' {
        { & $script:BuildScript -OutputPath (Join-Path $script:RepoRoot 'psEPM/out') } | Should -Throw '*must not be*'
    }

    It 'throws for -Publish without PSGALLERY_API_KEY before building or publishing' {
        $saved = $env:PSGALLERY_API_KEY
        try {
            $env:PSGALLERY_API_KEY = $null
            Mock Publish-Module { throw 'should not be called' }
            $fresh = Join-Path $TestDrive 'nokey'
            { & $script:BuildScript -OutputPath $fresh -Publish } | Should -Throw '*PSGALLERY_API_KEY*'
            Test-Path $fresh | Should -BeFalse
            Should -Invoke Publish-Module -Times 0 -Exactly
        } finally {
            $env:PSGALLERY_API_KEY = $saved
        }
    }
}
