# psEPM

PowerShell module for the Endpoint Privilege Manager (EPM) REST API.

API documentation: https://docs.cyberark.com/epm/latest/en/content/landingpages/lpdeveloper.htm

Session commands, set, endpoint and policy reads, and the download center commands work. See [ROADMAP.md](ROADMAP.md) for the planned command set and [DESIGN.md](DESIGN.md) for how the module is built.

## Requirements

- Windows PowerShell 5.1 or PowerShell 7+
- An Identity service user (OAuth2 confidential client) with an EPM role, the Identity tenant ID, and the web app ID

## Install

```powershell
git clone https://github.com/evanatta/psEPM.git
Import-Module ./psEPM/psEPM/psEPM.psd1
```

## Use

```powershell
$cred = Get-Credential
New-EPMSession -TenantId 'abc1234' -WebAppId 'mywebapp' -Credential $cred -BaseURI 'https://api-na.epm.cyberark.cloud'

Get-EPMSet
Get-EPMSet -Name 'Lab*' | Get-EPMEndpoint -Platform Windows
Get-EPMSet -Name 'Lab*' | Get-EPMEndpoint -First 1 | Get-EPMEndpoint -InventoryType OsInfo, Hardware
Get-EPMSet -Name 'Lab*' | Get-EPMEndpointInventory -InventoryType OsInfo
Get-EPMSet -Name 'Lab*' | Get-EPMEndpointSummary
Get-EPMSet -Name 'Lab*' | Get-EPMEndpointGroup -Type Dynamic
Get-EPMSet -Name 'Lab*' | Get-EPMPolicy -Name 'Elevate'
Get-EPMSet -Name 'Lab*' | Get-EPMAgentPackage -Platform Windows -Latest | Get-EPMPackageUrl

$group = New-EPMEndpointGroup -SetId $setId -Name 'Lab group' -Type Static -Description 'Lab machines'
$group | Set-EPMEndpointGroup -Description 'Lab machines, floor 2'
$group | Remove-EPMEndpointGroup -WhatIf
$group | Remove-EPMEndpointGroup

Get-EPMSession
Close-EPMSession
```

Use the regional EPM API URL for your tenant as `-BaseURI` (for example `https://api-na.epm.cyberark.cloud`).

To test with a token you already have:

```powershell
$token = Read-Host 'Token' -AsSecureString
New-EPMSession -Token $token -BaseURI 'https://api-na.epm.cyberark.cloud'
```

## Commands

| Command | What it does |
| --- | --- |
| New-EPMSession | Gets a token and starts a session |
| Get-EPMSession | Shows the current session |
| Use-EPMSession | Switches to a saved session |
| Close-EPMSession | Clears the session |
| Get-EPMSet | Lists sets |
| Get-EPMEndpoint | Searches endpoints or gets one endpoint's details |
| Get-EPMEndpointInventory | Gets one inventory section for many endpoints |
| Get-EPMEndpointSummary | Counts endpoints by agent version and platform |
| Get-EPMEndpointGroup | Searches endpoint groups |
| Get-EPMEndpointGroupValue | Lists endpoint attribute values for dynamic group filters |
| New-EPMEndpointGroup | Creates a static or dynamic endpoint group |
| Set-EPMEndpointGroup | Updates an endpoint group's name, description, or filter |
| Remove-EPMEndpointGroup | Deletes endpoint groups by ID or filter |
| Get-EPMPolicy | Searches policies or gets one policy's details |
| Get-EPMAgentPackage | Lists agent packages available to a set |
| Get-EPMEndpointPackage | Lists agent packages available for endpoints in a set |
| Get-EPMPackageConfiguration | Gets the installation configuration and key for a package |
| Get-EPMPackageUrl | Gets a signed download URL for a package |

Command help is in [docs/commands](docs/commands).

## Tests

```powershell
Install-Module Pester -MinimumVersion 5.5.0 -Scope CurrentUser
Invoke-Pester ./Tests
```

The tests use mocks and never call a tenant.

## CI

The GitHub Actions workflow is in `.github/workflows/ci.yml`. It runs PSScriptAnalyzer and Pester on Windows PowerShell 5.1 and PowerShell 7.

## Credit

The layout and conventions of this module are inspired by [psPAS](https://github.com/pspete/psPAS) by Pete Maan, which is MIT licensed.
