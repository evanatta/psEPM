# Get-EPMSignInAuditAggregation

Searches the aggregated endpoint sign-in audit events in a set.

API: `POST /Sets/{SetId}/signinaudits/aggregations/search?limit=<n>&nextCursor=<cursor>`

| Parameter | Description |
| --- | --- |
| SetId | Set ID, pipeline by property name |
| DateFrom | Adds `arrivalTime GE <UTC time>`. Optional |
| DateTo | Adds `arrivalTime LE <UTC time>`. Optional |
| LoginResult | `$true` adds `loginResult EQ "true"`, `$false` adds `loginResult EQ "false"`. Omit for both |
| Filter | Raw filter string, joined to the other clauses with `AND` |
| PageSize | 1 to 1000, default 1000 |
| First | Stop after this many results |

Output: `psEPM.SignInAuditAggregation` rows, the API row as returned. The API page lists fields such as `aggregatedBy`, `loginResult`, `totalEvents`, `firstEventDate`, `lastEventDate`, `lastLoginType`, `lastFailReason`, `lastFailReasonCode`, `loginProtocol`, `authenticationMethod`, `platform`, `policyName`, `newUser`, and `arrivalTime`. If the row has no `setId`, `SetId` is added. An existing `setId` is kept.

Examples:

```powershell
Get-EPMSignInAuditAggregation -SetId $setId -LoginResult $false
Get-EPMSet -Name 'Lab*' | Get-EPMSignInAuditAggregation -DateFrom (Get-Date).AddDays(-30) -LoginResult $true
```

Notes:

- Rows can hold user and computer names. Treat output as personal data.
- Per the API page, each row aggregates the sign-ins of one user on one endpoint with one result. `aggregatedBy` is `<user>,<endpoint>,<login status>`.
- `DateFrom` and `DateTo` filter on `arrivalTime`, sent unquoted as `yyyy-MM-ddTHH:mm:ssZ` in UTC. The filter table lists `timeLast` (the last event time) with a quoted value, which is also accepted through `-Filter`.
- `loginResult` takes a quoted value, as on the API page. The unquoted form `loginResult EQ true` is also accepted.
- `{"filter":""}` returns HTTP 400 `EPM050015E` on this API, although the filter is optional. With no filter parameters, or an empty or blank `-Filter`, the command sends `{}`.
- There is no `-EventType`. `eventType IN ...` returns HTTP 400 `EPM050015E`.
- Paging uses `nextCursor`, starting with `start`, URL-encoded. `sortBy` can't be sent with `nextCursor`, so the command sends no sort. The cursors of the event and policy audit aggregations do not advance, and no set in testing held sign-in audits, so this one is unconfirmed. The command drops a repeated page, stops, and warns when fewer than `filteredCount` rows came back. Keep `-PageSize` at 1000, the most the API returns in one request, and narrow the date window if a set has more rows than that.
