# Get-EPMApplicationCatalog

Searches the application catalog of a set: aggregated files, one row per file.

API: `POST /Sets/{SetId}/Files/Aggregations/search?limit=<n>&nextCursor=<cursor>`, or `?limit=<n>&sortBy=<field>&sortDir=<dir>` when sorted

| Parameter | Description |
| --- | --- |
| SetId | Set ID, pipeline by property name |
| OperatingSystem | `Windows`, `MacOS`, or `Linux`. Adds `operatingSystemType EQ <value>` |
| Filter | Raw filter string, joined to the other clauses with `AND` |
| SortBy | `FirstSeen` or `NumOfComputers`. Makes one sorted request, see the notes |
| SortDirection | `asc` or `desc`, default `desc`. Used with `SortBy` |
| PageSize | 1 to 1000, default 1000 |
| First | Stop after this many results |

Output: `psEPM.ApplicationCatalog` rows, the API file (`fileName`, `fileDisplayName`, `fileQualifier`, `applicationType`, `operatingSystemType`, `publisher`, `productName`, `fileVersion`, `numOfComputers`, `totalFiles`, `firstTimeSeen`, `arrivalTime`, `location`, `setId`, and others). The API row already has `setId`, which `SetId` reads. `SetId` is added only to a row without it.

Examples:

```powershell
Get-EPMApplicationCatalog -SetId $setId -OperatingSystem Windows -First 100
Get-EPMApplicationCatalog -SetId $setId -SortBy NumOfComputers
Get-EPMSet -Name 'Lab*' | Get-EPMApplicationCatalog -OperatingSystem MacOS -Filter 'fileName CONTAINS "setup"'
```

Notes:

- Files are aggregated by `fileQualifier`, built from the file name, hash, and application type.
- Rows hold file paths and a sample computer name. Treat output as sensitive.
- `operatingSystemType EQ Windows` works quoted or unquoted. The command sends it unquoted, like the API page.
- `{"filter":""}` returns HTTP 400 `EPM050015E`, although the filter is optional. With no filter parameters, or an empty or blank `-Filter`, the command sends `{}`.
- More than 1000 files can't be paged. `limit` above 1000 returns HTTP 400 `EPM000002E`. A `nextCursor` is returned only when the request sends `nextCursor=start`, and following it returns the first page again. `offset` is ignored too. The command drops the repeated page, stops, and warns "Returned <n> of <filteredCount> results". Keep `-PageSize` at 1000 and narrow the search with `-OperatingSystem` or `-Filter`.
- To see the top of a large catalog, use `-SortBy`, for example `-SortBy NumOfComputers` for the most widespread files first. The API page says sorting is disabled when `nextCursor` is sent, so a sorted search is one request without a cursor, and warns when `filteredCount` is larger than the page. `-SortBy` values other than `FirstSeen` and `NumOfComputers` return HTTP 400.
- `arrivalTime` filters work here too, for example `-Filter 'arrivalTime GE 2026-10-01T00:00:00Z'`.
