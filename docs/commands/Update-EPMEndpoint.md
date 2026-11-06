# Update-EPMEndpoint

Upgrades the agent on endpoints in a set to a published package version.

API: `POST /Sets/{SetId}/endpoints/upgrade` with `{"filter": "...", "versions": [{"platform": "...", "architecture": "...", "version": "..."}], "returnIds": true, "includeAll": false}`

| Parameter | Description |
| --- | --- |
| SetId | Source set ID, pipeline by property name |
| EndpointId | One or more endpoint IDs (GUIDs), pipeline by property name, so `Get-EPMEndpoint` rows pipe in. One ID sends `id EQ "<id>"`, several send `id IN <a>,<b>` |
| Filter | Raw filter clause, joined to the ID clause with `AND`. Not taken from the pipeline |
| WhatIf, Confirm | Standard ShouldProcess switches, `ConfirmImpact` High. `-WhatIf` sends nothing |
| Platform | `Windows`, `MacOS`, or `Linux` |
| Architecture | `x64` or `arm64` |
| Version | Agent version, for example `26.10.1.115`. Must be a published package version |

Output: `psEPM.EndpointChange` with `SetId`, `Action`, `Filter`, `AppliedIds`, and `Statuses` (`Action` is `Upgrade`).

Examples:

```powershell
$version = (Get-EPMAgentPackage -SetId $setId | Where-Object { $_.packageOS -eq 'Windows' -and $_.packageArch -eq 'x64' -and $_.packageType -eq 'latest' }).Version
Update-EPMEndpoint -SetId $setId -EndpointId $endpointId -Platform Windows -Architecture x64 -Version $version -WhatIf
Get-EPMEndpoint -SetId $setId -Filter 'name EQ "APITEST-PC"' | Update-EPMEndpoint -Platform Windows -Architecture x64 -Version $version -WhatIf
```

Notes:

- The API page says that an empty filter upgrades every endpoint. The command never sends one.
- `versions` is sent as a JSON array with one entry, also on Windows PowerShell 5.1. Without `versions` the API returns HTTP 500.
- `Architecture` takes `x64` and `arm64`, the `packageArch` values of Windows packages. The OS-style values in the API page's description, such as `OS_WIN64` and `OS_WIN_X64`, return HTTP 400 "Input parameter for architecture value is invalid". Other `packageArch` values, such as `x86` and the Linux values, are not offered because they have not been verified with this API.
- `Version` must be a published package version. Look it up with `Get-EPMAgentPackage`, not the removed download-packages API. A version with no published package returns HTTP 500 `EPM000001E`.
- Upgrading to a version older than the installed one is not applied: the status is `ERROR_ENDPOINT_VERSION_IS_HIGHER`.
- `-EndpointId` or a non-empty `-Filter` is required. A missing, empty, or blank filter is rejected before any request.
- The body always has `returnIds: true`, so `AppliedIds` lists the endpoints the command was dispatched to, and `includeAll: false`. There is no parameter to apply the command to every endpoint in a set.
- Filter fields from the API page include `id` (`EQ`, `IN`), `name` (`EQ`, `IN`, `CONTAINS`), `platform`, `connectionStatus`, `agentVersion`, `osVersion`, `ip`, `lastConnected`, and `upgradeStatus`. `hostname` works as an undocumented alias of `name`.
- A filter that matches nothing returns HTTP 200 with empty `appliedIds` and `statuses`, and the command warns.
- `Statuses` maps a validation status name to a count, for example `OK`. The keys are strings, although one API page types them as integers.
- Test a filter with `Get-EPMEndpoint -Filter` first, then run with `-WhatIf`.
