BeforeAll {
    $script:ModuleRoot = Join-Path (Split-Path -Parent $PSScriptRoot) 'psEPM'
    Import-Module (Join-Path $script:ModuleRoot 'psEPM.psd1') -Force
}

Describe 'Module' {
    It 'has a valid manifest' {
        { Test-ModuleManifest -Path (Join-Path $script:ModuleRoot 'psEPM.psd1') -ErrorAction Stop } | Should -Not -Throw
    }

    It 'exports every public function file' {
        $files = Get-ChildItem -Path (Join-Path $script:ModuleRoot 'Public') -Recurse -Filter '*.ps1' | ForEach-Object { $_.BaseName }
        $exported = (Get-Module psEPM).ExportedFunctions.Keys
        foreach ($name in $files) {
            $exported | Should -Contain $name
        }
    }

    It 'does not export private functions' {
        (Get-Module psEPM).ExportedFunctions.Keys | Should -Not -Contain 'Invoke-EPMRestMethod'
    }

    It 'uses the EPM noun prefix and approved verbs' {
        $approved = (Get-Verb).Verb
        foreach ($name in (Get-Module psEPM).ExportedFunctions.Keys) {
            $parts = $name -split '-', 2
            $approved | Should -Contain $parts[0]
            $parts[1] | Should -Match '^EPM'
        }
    }

    It 'has no comment lines in code files' {
        $files = Get-ChildItem -Path $script:ModuleRoot -Recurse -Include '*.ps1', '*.psm1', '*.psd1'
        foreach ($file in $files) {
            $tokens = $null
            $parseErrors = $null
            [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$parseErrors) | Out-Null
            @($tokens | Where-Object { $_.Kind -eq 'Comment' }).Count | Should -Be 0 -Because $file.Name
        }
    }
}
