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
Get-EPMEndpoint -SetId $setId -Name 'PC0' | Add-EPMEndpointGroupMember -GroupId $group.GroupId
Get-EPMEndpoint -SetId $setId -Name 'PC0' | Remove-EPMEndpointGroupMember -GroupId $group.GroupId -WhatIf
$group | Remove-EPMEndpointGroup -WhatIf
$group | Remove-EPMEndpointGroup

$policy = New-EPMPolicy -SetId $setId -Name 'Allow notepad' -FileName 'notepad.exe' -Description 'Inactive test'
$policy | Set-EPMPolicy -Description 'Inactive test, reviewed'
$policy | Remove-EPMPolicy -WhatIf
$policy | Remove-EPMPolicy

Export-EPMPolicy -SetId $setId -GroupType All -OutFile .\policies.epmp
$appGroup = New-EPMApplicationGroup -SetId $setId -Name 'Editors' -FileName 'notepad.exe' -Description 'Text editors'
$appGroup | Set-EPMApplicationGroup -Description 'Approved text editors'
$appGroup | Remove-EPMApplicationGroup

Get-EPMSet -Name 'Lab*' | Get-EPMAgentConfiguration
Get-EPMAgentConfiguration -SetId $setId -Default
Get-EPMSet -Name 'Lab*' | Get-EPMThreatProtectionPolicy | Where-Object IsActive
Get-EPMSet -Name 'Lab*' | Get-EPMPolicyRecommendation

Get-EPMEvent -SetId $setId -DateFrom (Get-Date).AddDays(-7) -EventType ElevationRequest -First 50
Get-EPMEventAggregation -SetId $setId -DateFrom (Get-Date).AddDays(-30) | Sort-Object totalEvents -Descending
Get-EPMPolicyAudit -SetId $setId -DateFrom (Get-Date).AddDays(-7) -EventType Block -First 50
Get-EPMPolicyAuditAggregation -SetId $setId -DateFrom (Get-Date).AddDays(-30)

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
| Add-EPMEndpointGroupMember | Adds endpoints to a static group by ID or filter |
| Remove-EPMEndpointGroupMember | Removes endpoints from a static group by ID or filter |
| Get-EPMPolicy | Searches policies or gets one policy's details |
| New-EPMPolicy | Creates a policy, inactive by default |
| Set-EPMPolicy | Updates a policy by merging fields or replacing the definition |
| Remove-EPMPolicy | Deletes policies |
| Export-EPMPolicy | Exports a set's policies as an .epmp file |
| Get-EPMApplicationGroup | Searches application groups or gets one group's details |
| New-EPMApplicationGroup | Creates an application group |
| Set-EPMApplicationGroup | Updates an application group |
| Remove-EPMApplicationGroup | Deletes application groups |
| Get-EPMAgentConfiguration | Searches agent configurations, gets details, or gets the product default |
| Get-EPMThreatProtectionPolicy | Lists threat protection policies |
| Get-EPMPolicyRecommendation | Lists policy recommendations |
| Get-EPMEvent | Searches raw events by date, event type, or filter |
| Get-EPMEventAggregation | Searches aggregated events, one row per application and event type |
| Get-EPMPolicyAudit | Searches policy audit events by date, event type, or filter |
| Get-EPMPolicyAuditAggregation | Searches aggregated policy audits, one row per application and event type |
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
