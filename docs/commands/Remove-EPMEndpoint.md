# Remove-EPMEndpoint

Deletes endpoint records from a set.

API: `POST /Sets/{SetId}/Endpoints/delete` with `{"filter": "...", "force": false, "returnIds": true, "includeAll": false}`

| Parameter | Description |
| --- | --- |
| SetId | Source set ID, pipeline by property name |
| EndpointId | One or more endpoint IDs (GUIDs), pipeline by property name, so `Get-EPMEndpoint` rows pipe in. One ID sends `id EQ "<id>"`, several send `id IN <a>,<b>` |
| Filter | Raw filter clause, joined to the ID clause with `AND`. Not taken from the pipeline |
| WhatIf, Confirm | Standard ShouldProcess switches, `ConfirmImpact` High. `-WhatIf` sends nothing |
| Force | Sends `force: true`, which deletes the endpoint even if it is connected. Default `false` |

Output: `psEPM.EndpointChange` with `SetId`, `Action`, `Filter`, `AppliedIds`, and `Statuses` (`Action` is `Delete`).

Examples:

```powershell
Remove-EPMEndpoint -SetId $setId -EndpointId $endpointId -WhatIf
Get-EPMEndpoint -SetId $setId -Filter 'name EQ "APITEST-PC" AND connectionStatus EQ Disconnected' | Remove-EPMEndpoint -WhatIf
```

Notes:

- This deletes the endpoint record in EPM. It does not uninstall the agent. To remove the agent, use `Uninstall-EPMEndpoint`.
- The API page's result descriptions say "uninstall" for `appliedIds` and `statuses`. The route deletes.
- `-EndpointId` or a non-empty `-Filter` is required. A missing, empty, or blank filter is rejected before any request.
- The body always has `returnIds: true`, so `AppliedIds` lists the endpoints the command was dispatched to, and `includeAll: false`. There is no parameter to apply the command to every endpoint in a set.
- Filter fields from the API page include `id` (`EQ`, `IN`), `name` (`EQ`, `IN`, `CONTAINS`), `platform`, `connectionStatus`, `agentVersion`, `osVersion`, `ip`, `lastConnected`, and `upgradeStatus`. `hostname` works as an undocumented alias of `name`.
- A filter that matches nothing returns HTTP 200 with empty `appliedIds` and `statuses`, and the command warns.
- `Statuses` maps a validation status name to a count, for example `OK`. The keys are strings, although one API page types them as integers.
- Test a filter with `Get-EPMEndpoint -Filter` first, then run with `-WhatIf`.
