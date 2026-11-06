# Get-EPMEvent

Searches the detailed raw events in a set.

API: `POST /Sets/{SetId}/Events/Search?limit=<n>&nextCursor=<cursor>`

| Parameter | Description |
| --- | --- |
| SetId | Set ID, pipeline by property name |
| DateFrom | Adds `arrivalTime GE <UTC time>`. Optional |
| DateTo | Adds `arrivalTime LE <UTC time>`. Optional |
| EventType | One or more of `Launch`, `Block`, `Trust`, `ElevationRequest`, `ManualRequest`, `Installation`, `StartElevated`, `AttackAttempt`. Adds `eventType IN <a>,<b>` |
| Filter | Raw filter string, joined to the other clauses with `AND` |
| PageSize | 1 to 1000, default 1000 |
| First | Stop after this many results |

Output: `psEPM.Event` rows, the API event (`eventId`, `eventType`, `arrivalTime`, `firstEventDate`, `lastEventDate`, `eventCount`, `computerName`, `userName`, `fileName`, `filePath`, `hash`, `publisher`, `policyName`, `justification`, and others) plus `SetId`. Property names are not case sensitive, so `EventId` reads `eventId`.

Examples:

```powershell
Get-EPMEvent -SetId $setId -DateFrom (Get-Date).AddDays(-7) -First 50
Get-EPMEvent -SetId $setId -EventType ElevationRequest, ManualRequest -DateFrom '2026-10-01' -DateTo '2026-10-31T23:59:59Z'
Get-EPMSet -Name 'Lab*' | Get-EPMEvent -EventType Block -Filter 'fileName CONTAINS "setup"'
```

Notes:

- The date field is `arrivalTime`, sent as `yyyy-MM-ddTHH:mm:ssZ`. Dates are converted to UTC first. A date without a time zone, such as `'2026-10-01'`, is read as local time.
- `DateFrom` is not required. With no filter the body is `{}` and the search returns every event the set holds.
- `eventType` takes only `IN`, even for one type. `eventType EQ` returns HTTP 400 with a generic server error.
- The event type values are not listed on the API page. The eight values above return 200 live. Other names return HTTP 400 without naming the bad value. The page also lists `ALL`, but `eventType IN ALL` returns no events, so it is not offered.
- Paging uses `nextCursor`, starting with `start`. The cursor is URL-encoded. Paging stops when `filteredCount` results have been returned, when the API returns an empty cursor, or when it returns the same cursor or the same page again. If fewer than `filteredCount` results came back, a warning says so.
- `offset` also advances on this search, but the cursor is what the API page documents.
- No API returns one event by ID. `GET /Sets/{SetId}/Events/{EventId}` returns HTTP 405 (the route allows only `DELETE`), and `GET /Events/{EventId}` returns 404. To find one event, filter the search.
