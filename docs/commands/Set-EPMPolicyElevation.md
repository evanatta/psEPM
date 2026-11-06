# Set-EPMPolicyElevation

Approves or rejects an end user's temporary elevation request.

API: `POST /Sets/{SetId}/Policies/Server/Elevate` to approve, `DELETE /Sets/{SetId}/Policies/Server/Elevate` to reject, both with `{"SendEmail": false, "Filter": "aggregatedBy EQ \"<value>\"", "Elevation": 1}`

| Parameter | Description |
| --- | --- |
| SetId | Set ID, pipeline by property name |
| AggregatedBy | The request's `aggregatedBy` value, pipeline by property name. Sends `aggregatedBy EQ "<value>"`. Double quotes are rejected |
| Filter | Raw filter clause, for example `aggregatedBy IN "<a>","<b>"`. Joined to the `AggregatedBy` clause with `AND`. Not taken from the pipeline |
| Elevation | `Approve` sends `POST` with `Elevation: 1`. `Reject` sends `DELETE` with `Elevation: 2` |
| SendEmail | Sends `SendEmail: true`, which emails the requestor. Default `false` |
| WhatIf, Confirm | Standard ShouldProcess switches, `ConfirmImpact` High. `-WhatIf` sends nothing |

Output: `psEPM.PolicyElevation`. On approve this is the policy entity the API returns, with `SetId` added. If the API returns no body, for example on reject, it is `SetId`, `Elevation`, and `Filter`.

Examples:

```powershell
Get-EPMEventAggregation -SetId $setId -EventType ElevationRequest | Select-Object aggregatedBy
Set-EPMPolicyElevation -SetId $setId -AggregatedBy $aggregatedBy -Elevation Approve -WhatIf
Set-EPMPolicyElevation -SetId $setId -AggregatedBy $aggregatedBy -Elevation Reject -SendEmail -WhatIf
```

Notes:

- Approving creates a temporary policy for 24 hours, based on the most recent request in the aggregated event. EPM deletes the policy after 3 months.
- Find requests with `Get-EPMEvent -EventType ElevationRequest` (or `Get-EPMEventAggregation -EventType ElevationRequest`), then take `aggregatedBy` from the row. The API page describes the value as `<hash or AdminTaskId>,<eventtype>`.
- The API page's body table lists an `aggregatedBy` field, but its examples send a `Filter` string, such as `"Filter": "aggregatedBy EQ \"16,32\""`. The command sends `Filter`, following the examples.
- The API page lists `POST` as approve and `DELETE` as reject, with `Elevation` 1 (approve) or 2 (reject) in both bodies. `OPTIONS` on the route allows `DELETE` and `POST`.
- `-AggregatedBy` or a non-empty `-Filter` is required. A missing, empty, or blank filter is rejected before any request.
- A fake or unknown `aggregatedBy` returns HTTP 400 `EPM000002E`, and no policy is created. This was checked once with a fake value on a test set in November 2026.
- No live approve or reject of a real request has been run. The success output shape is taken from the API page.
- There is no documented `GET` on this route. A `GET` returns HTTP 400, so there is no `Get-EPMPolicyElevation`.
