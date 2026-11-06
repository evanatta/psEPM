# Uninstall-EPMEndpoint

Sends an uninstall command to the agent on endpoints in a set.

API: `POST /Sets/{SetId}/endpoints/uninstall` with `{"filter": "...", "returnIds": true, "includeAll": false}`

| Parameter | Description |
| --- | --- |
| SetId | Source set ID, pipeline by property name |
| EndpointId | One or more endpoint IDs (GUIDs), pipeline by property name, so `Get-EPMEndpoint` rows pipe in. One ID sends `id EQ "<id>"`, several send `id IN <a>,<b>` |
| Filter | Raw filter clause, joined to the ID clause with `AND`. Not taken from the pipeline |
| WhatIf, Confirm | Standard ShouldProcess switches, `ConfirmImpact` High. `-WhatIf` sends nothing |

Output: `psEPM.EndpointChange` with `SetId`, `Action`, `Filter`, `AppliedIds`, and `Statuses` (`Action` is `Uninstall`).

Examples:

```powershell
Uninstall-EPMEndpoint -SetId $setId -EndpointId $endpointId -WhatIf
Get-EPMEndpoint -SetId $setId -Filter 'name EQ "APITEST-PC"' | Uninstall-EPMEndpoint -WhatIf
```

Notes:

- This dispatches an uninstall to the agent. It is not the same as `Remove-EPMEndpoint`, which deletes the endpoint record. `AppliedIds` lists the endpoints the command was dispatched to, not completed uninstalls.
- `-EndpointId` or a non-empty `-Filter` is required. A missing, empty, or blank filter is rejected before any request.
- The body always has `returnIds: true`, so `AppliedIds` lists the endpoints the command was dispatched to, and `includeAll: false`. There is no parameter to apply the command to every endpoint in a set.
- Filter fields from the API page include `id` (`EQ`, `IN`), `name` (`EQ`, `IN`, `CONTAINS`), `platform`, `connectionStatus`, `agentVersion`, `osVersion`, `ip`, `lastConnected`, and `upgradeStatus`. `hostname` works as an undocumented alias of `name`.
- A filter that matches nothing returns HTTP 200 with empty `appliedIds` and `statuses`, and the command warns.
- `Statuses` maps a validation status name to a count, for example `OK`. The keys are strings, although one API page types them as integers.
- Test a filter with `Get-EPMEndpoint -Filter` first, then run with `-WhatIf`.
