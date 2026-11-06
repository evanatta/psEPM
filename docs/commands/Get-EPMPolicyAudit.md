# Get-EPMPolicyAudit

Searches the raw policy audit events in a set.

API: `POST /Sets/{SetId}/policyaudits/search?limit=<n>&nextCursor=<cursor>`

| Parameter | Description |
| --- | --- |
| SetId | Set ID, pipeline by property name |
| DateFrom | Adds `arrivalTime GE <UTC time>`. Optional |
| DateTo | Adds `arrivalTime LE <UTC time>`. Optional |
| EventType | One or more of `Launch`, `Block`, `Trust`, `ElevationRequest`, `ManualRequest`, `Installation`, `StartElevated`, `AttackAttempt`. Adds `eventType IN <a>,<b>` |
| Filter | Raw filter string, joined to the other clauses with `AND` |
| PageSize | 1 to 1000, default 1000 |
| First | Stop after this many results |

Output: `psEPM.PolicyAudit` rows, the API audit event (`eventId`, `eventType`, `arrivalTime`, `firstEventDate`, `lastEventDate`, `eventCount`, `computerName`, `userName`, `fileName`, `filePath`, `hash`, `publisher`, `policyName`, `policyAction`, `justification`, `setId`, and others). The API row already has `setId`, and property names are not case sensitive, so `SetId` reads it. `SetId` is added only to a row without it.

Examples:

```powershell
Get-EPMPolicyAudit -SetId $setId -DateFrom (Get-Date).AddDays(-7) -First 50
Get-EPMPolicyAudit -SetId $setId -DateFrom '2026-10-01' -EventType Block, StartElevated
Get-EPMSet -Name 'Lab*' | Get-EPMPolicyAudit -EventType Block -Filter 'policyName CONTAINS "Block"' -First 100
```

Notes:

- The date field is `arrivalTime`, the time the service received the audit, not the time of the event. It is sent as `yyyy-MM-ddTHH:mm:ssZ`. Dates are converted to UTC first. A date without a time zone, such as `'2026-10-01'`, is read as local time. For the event time, filter `eventDate GE` / `eventDate LE` with `-Filter`.
- `DateFrom` is not required. With no filter the body is `{}` and the search returns every audit the set holds. An empty or blank `-Filter` is not sent.
- `eventType` takes only `IN`, even for one type. `eventType EQ` returns HTTP 400.
- The event type values are not listed on the API page. The eight values above return 200 live. Other names return HTTP 400 without naming the bad value. `ALL`, listed on the page, is not offered.
- Paging uses `nextCursor`, starting with `start`, URL-encoded. The cursor advances on this search. Paging stops when `filteredCount` results have been returned, on an empty cursor, or when the API returns the same cursor or page again, with a warning if fewer than `filteredCount` came back. Use `-First` or a date window on a large set.
- No API returns one audit by ID. `GET /Sets/{SetId}/policyaudits/{EventId}` returns HTTP 404. To find one audit, filter the search.
