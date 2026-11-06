# Move-EPMEndpoint

Moves endpoints to another set.

API: `POST /Sets/{SetId}/Endpoints/moveset` with `{"filter": "...", "targetSet": "<TargetSetId>", "returnIds": true, "includeAll": false}`

| Parameter | Description |
| --- | --- |
| SetId | Source set ID, pipeline by property name |
| EndpointId | One or more endpoint IDs (GUIDs), pipeline by property name, so `Get-EPMEndpoint` rows pipe in. One ID sends `id EQ "<id>"`, several send `id IN <a>,<b>` |
| Filter | Raw filter clause, joined to the ID clause with `AND`. Not taken from the pipeline |
| WhatIf, Confirm | Standard ShouldProcess switches, `ConfirmImpact` High. `-WhatIf` sends nothing |
| TargetSetId | ID (GUID) of the set to move the endpoints to. Must differ from `SetId` |

Output: `psEPM.EndpointChange` with `SetId`, `Action`, `Filter`, `AppliedIds`, and `Statuses`, and `TargetSetId` (`Action` is `Move`).

Examples:

```powershell
Move-EPMEndpoint -SetId $setId -EndpointId $endpointId -TargetSetId $targetSetId -WhatIf
Get-EPMEndpoint -SetId $setId -Filter 'name EQ "APITEST-PC"' | Move-EPMEndpoint -TargetSetId $targetSetId -WhatIf
```

Notes:

- The move is asynchronous. The endpoint stays in the source set with a `moveSetStatus` (`Initiating`, then `StartingRegistration`) until its agent checks in, then appears in the target set.
- The endpoint gets a new ID in the target set. Scripts that track an endpoint by ID lose it after a move.
- There is no API to cancel a pending move.
- A target set equal to the source set returns HTTP 500 `EPM000001E`, even when the filter matches nothing. The command rejects it before sending.
- `-EndpointId` or a non-empty `-Filter` is required. A missing, empty, or blank filter is rejected before any request.
- The body always has `returnIds: true`, so `AppliedIds` lists the endpoints the command was dispatched to, and `includeAll: false`. There is no parameter to apply the command to every endpoint in a set.
- Filter fields from the API page include `id` (`EQ`, `IN`), `name` (`EQ`, `IN`, `CONTAINS`), `platform`, `connectionStatus`, `agentVersion`, `osVersion`, `ip`, `lastConnected`, and `upgradeStatus`. `hostname` works as an undocumented alias of `name`.
- A filter that matches nothing returns HTTP 200 with empty `appliedIds` and `statuses`, and the command warns.
- `Statuses` maps a validation status name to a count, for example `OK`. The keys are strings, although one API page types them as integers.
- Test a filter with `Get-EPMEndpoint -Filter` first, then run with `-WhatIf`.
