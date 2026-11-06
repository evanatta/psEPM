BeforeAll {
    $script:ModuleRoot = Join-Path (Split-Path -Parent $PSScriptRoot) 'psEPM'
    Import-Module (Join-Path $script:ModuleRoot 'psEPM.psd1') -Force
    $script:FormatPath = Join-Path $script:ModuleRoot 'psEPM.Format.ps1xml'
}

Describe 'Format views' {
    It 'is listed in the manifest and exists' {
        $manifest = Import-PowerShellDataFile -Path (Join-Path $script:ModuleRoot 'psEPM.psd1')
        $manifest.FormatsToProcess | Should -Contain 'psEPM.Format.ps1xml'
        Test-Path $script:FormatPath | Should -BeTrue
    }

    It 'only names types the module emits, with matching headers and columns' {
        [xml]$xml = Get-Content -Path $script:FormatPath -Raw
        $code = (Get-ChildItem -Path $script:ModuleRoot -Recurse -Filter '*.ps1' | ForEach-Object { Get-Content -Path $_.FullName -Raw }) -join "`n"
        $views = @($xml.Configuration.ViewDefinitions.View)
        $views.Count | Should -BeGreaterThan 10
        foreach ($view in $views) {
            $type = $view.ViewSelectedBy.TypeName
            $code | Should -Match ("'" + [regex]::Escape($type) + "'") -Because $type
            @($view.TableControl.TableHeaders.TableColumnHeader).Count | Should -Be @($view.TableControl.TableRowEntries.TableRowEntry.TableColumnItems.TableColumnItem).Count -Because $type
        }
        @($views | ForEach-Object { $_.ViewSelectedBy.TypeName } | Group-Object | Where-Object { $_.Count -gt 1 }).Count | Should -Be 0
    }

    It 'loads a table view for the main list types' {
        foreach ($type in 'psEPM.Set', 'psEPM.Endpoint', 'psEPM.Policy', 'psEPM.EndpointGroup', 'psEPM.ApplicationGroup', 'psEPM.Event', 'psEPM.AdminAudit', 'psEPM.AgentPackage', 'psEPM.ApplicationCatalog') {
            $data = Get-FormatData -TypeName $type
            $data | Should -Not -BeNullOrEmpty -Because $type
            $data.FormatViewDefinition[0].Control.GetType().Name | Should -Be 'TableControl'
        }
    }

    It 'shows the view columns for a set row' {
        $row = [pscustomobject]@{ Id = 's1'; Name = 'APITEST_Set'; SetType = 'Regular'; IsReady = $true; Description = 'd'; SetId = 's1' }
        $row.PSObject.TypeNames.Insert(0, 'psEPM.Set')
        $text = $row | Out-String
        $text | Should -Match 'Name\s+SetType\s+IsReady\s+SetId'
        $text | Should -Not -Match 'Description'
    }
}
