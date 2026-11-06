# Get-EPMPolicyAuditAggregation

Searches the aggregated policy audits in a set.

API: `POST /Sets/{SetId}/policyaudits/aggregations/search?limit=<n>&nextCursor=<cursor>`

| Parameter | Description |
| --- | --- |
| SetId | Set ID, pipeline by property name |
| DateFrom | Adds `arrivalTime GE <UTC time>`. Optional |
| DateTo | Adds `arrivalTime LE <UTC time>`. Optional |
| EventType | One or more of `Launch`, `Block`, `Trust`, `ElevationRequest`, `ManualRequest`, `Installation`, `StartElevated`, `AttackAttempt`. Adds `eventType IN <a>,<b>` |
| Filter | Raw filter string, joined to the other clauses with `AND` |
| PageSize | 1 to 1000, default 1000 |
| First | Stop after this many results |

Output: `psEPM.PolicyAuditAggregation` rows, the API row (`aggregatedBy`, `aggregatedByBase64`, `eventType`, `hash`, `fileQualifier`, `publisher`, `policyName`, `policyAction`, `totalEvents`, `affectedComputers`, `affectedUsers`, `firstEventDate`, `lastEventDate`, `lastEventId`, `lastEventFileName`, `lastEventComputerName`, `lastEventUserName`, and others) plus `SetId`.

Examples:

```powershell
Get-EPMPolicyAuditAggregation -SetId $setId -DateFrom (Get-Date).AddDays(-30)
Get-EPMSet -Name 'Lab*' | Get-EPMPolicyAuditAggregation -EventType Block | Sort-Object totalEvents -Descending
```

Notes:

- Each row is one application per event type, keyed by `aggregatedBy`: the application's SHA1 (the `hash` value without its `SHA1##` prefix) and the policy name that audited it, separated by a comma. The policy sets the event type, so an application audited by two policies or with two event types appears once for each. `totalEvents`, `affectedComputers`, and `affectedUsers` count across the matching audits.
- A date filter selects applications that have audits in the window.
- The filter fields, `DateFrom`, and `EventType` work as in `Get-EPMPolicyAudit`: `arrivalTime` in UTC, `eventType IN` only, and no filter needed.
- `{"filter":""}` returns HTTP 400 `EPM050015E` on this API, although the filter is optional. With no filter parameters, or an empty or blank `-Filter`, the command sends `{}`.
- `sortBy` can't be sent with `nextCursor`, so the command sends no sort. Sort the output instead.
- Live, the aggregation cursor did not advance. The second request returned the same cursor and the same rows, URL-encoded or not, with or without an `arrivalTime` filter, and `offset` is ignored. A cursor is also returned when the page already holds every row. The command drops a repeated page, stops, and warns when fewer than `filteredCount` rows came back. Keep `-PageSize` at 1000, the most the API returns in one request, and narrow the date window if a set has more rows than that.
