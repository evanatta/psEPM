# Get-EPMEventAggregation

Searches the aggregated events in a set.

API: `POST /Sets/{SetId}/events/aggregations/search?limit=<n>&nextCursor=<cursor>`

| Parameter | Description |
| --- | --- |
| SetId | Set ID, pipeline by property name |
| DateFrom | Adds `arrivalTime GE <UTC time>`. Optional |
| DateTo | Adds `arrivalTime LE <UTC time>`. Optional |
| EventType | One or more of `Launch`, `Block`, `Trust`, `ElevationRequest`, `ManualRequest`, `Installation`, `StartElevated`, `AttackAttempt`. Adds `eventType IN <a>,<b>` |
| Filter | Raw filter string, joined to the other clauses with `AND` |
| PageSize | 1 to 1000, default 1000 |
| First | Stop after this many results |

Output: `psEPM.EventAggregation` rows, the API row (`aggregatedBy`, `eventType`, `hash`, `fileQualifier`, `publisher`, `totalEvents`, `affectedComputers`, `affectedUsers`, `firstEventDate`, `lastEventDate`, `lastEventId`, `lastEventFileName`, `lastEventComputerName`, `lastEventUserName`, `policyName`, and others) plus `SetId`.

Examples:

```powershell
Get-EPMEventAggregation -SetId $setId -DateFrom (Get-Date).AddDays(-30)
Get-EPMSet -Name 'Lab*' | Get-EPMEventAggregation -EventType ElevationRequest | Sort-Object totalEvents -Descending
```

Notes:

- Each row is one application for one event type, keyed by `hash`. The same application appears once for each event type it has. `totalEvents`, `affectedComputers`, and `affectedUsers` count across the matching events.
- A date filter selects applications that have events in the window.
- The filter fields, `DateFrom`, and `EventType` work as in `Get-EPMEvent`: `arrivalTime` in UTC, `eventType IN` only, and no filter needed.
- The API page uses lowercase `events` in the path. `Events` also works.
- Paging uses `nextCursor`, starting with `start`. `sortBy` can't be sent with `nextCursor`, so the command sends no sort. Sort the output instead.
- Live, the aggregation cursor did not advance. With `limit=1` the second request returned the same cursor and the same row, with or without an `arrivalTime` filter, and `offset` is ignored. The command drops a repeated page, stops, and warns when fewer than `filteredCount` rows came back. Keep `-PageSize` at 1000, the most the API returns in one request, and narrow the date window if a set has more rows than that.
