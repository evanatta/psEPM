# Get-EPMFileInstance

Searches the raw file details of a set: each instance of a file on an endpoint.

API: `POST /Sets/{SetId}/Files/FileInstances/Search?limit=<n>&nextCursor=<cursor>`

| Parameter | Description |
| --- | --- |
| SetId | Set ID, pipeline by property name |
| DateFrom | Adds `arrivalTime GE <UTC time>`. Optional |
| DateTo | Adds `arrivalTime LE <UTC time>`. Optional |
| Filter | Raw filter string, joined to the other clauses with `AND` |
| PageSize | 1 to 1000, default 1000 |
| First | Stop after this many results |

Output: `psEPM.FileInstance` rows, the API file instance (`fileInstId`, `fileName`, `fileDisplayName`, `fileQualifier`, `applicationType`, `operatingSystemType`, `publisher`, `productName`, `fileVersion`, `location`, `computerName`, `agentId`, `firstTimeSeen`, `arrivalTime`, `hash`, `hashSha256`, and others) plus `SetId`.

Examples:

```powershell
Get-EPMFileInstance -SetId $setId -DateFrom (Get-Date).AddDays(-30) -First 100
Get-EPMSet -Name 'Lab*' | Get-EPMFileInstance -DateFrom '2026-10-01' -Filter 'operatingSystemType EQ Windows'
```

Notes:

- Rows hold computer names, file paths, and hashes. Treat output as sensitive.
- `DateFrom` and `DateTo` filter on `arrivalTime`, the time the service received the file instance, sent unquoted as `yyyy-MM-ddTHH:mm:ssZ` in UTC. A date without a time zone, such as `'2026-10-01'`, is read as local time. `timeSeen GE/LE` filters on the time the file was first seen, through `-Filter`.
- `DateFrom` is not required. With no filter the body is `{}`. `{"filter":""}` is accepted on this search, but an empty or blank `-Filter` is not sent.
- There is no `-EventType`. `eventType IN ...` returns HTTP 400 `EPM050015E`.
- Paging uses `nextCursor`, starting with `start`, URL-encoded. Unlike the application catalog, the cursor advances here. `limit` above 1000 returns HTTP 400 `EPM000002E`. `offset` also advances.
- Live, a full pull ended with an empty page and a null cursor after fewer rows than `filteredCount`, and some `fileInstId` values repeated across pages. The command then warns "Returned <n> of <filteredCount> results". Treat `filteredCount` as approximate.
- The API page lists `sortBy` values `TimeSeen` and `NumOfComputers`. `NumOfComputers` returns HTTP 400, and the page says sorting is disabled with `nextCursor`, so the command doesn't sort.
- No API returns one file instance by ID. Filter with `fileInstId EQ "<id>"` instead.
