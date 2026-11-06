# Get-EPMAdminAudit

Gets the set admin audit: the actions administrators performed in a set.

API: `GET /Sets/{SetId}/AdminAudit?DateFrom=<UTC time>&DateTo=<UTC time>&offset=<n>&limit=<n>`

| Parameter | Description |
| --- | --- |
| SetId | Set ID, pipeline by property name |
| DateFrom | Start of the window. Optional, see the notes |
| DateTo | End of the window. Optional, see the notes |
| PageSize | 1 to 500, default 500 |
| First | Stop after this many results |

Output: `psEPM.AdminAudit` rows (`EventTime`, `Feature`, `Description`, `PermissionDescription`, `Administrator`, `Role`, `LoggedAt`, `LoggedFrom`, `InternalSessionId`, `SetName`) plus `SetId`.

Examples:

```powershell
Get-EPMAdminAudit -SetId $setId -DateFrom (Get-Date).AddDays(-30) -First 100
Get-EPMAdminAudit -SetId $setId -DateFrom '2026-10-01T00:00:00Z' -DateTo '2026-10-31T23:59:59Z' | Group-Object Feature
Get-EPMSet -Name 'Lab*' | Get-EPMAdminAudit
```

Notes:

- Rows hold administrator names and IP addresses. Treat output as personal data.
- This is the set admin audit. The account admin audit, `GET /Account/AdminAudit`, returns HTTP 404 and has no command.
- The API page marks this API as deprecated in favor of the SIEM integration API, and What's New says it will be removed by April 2027. The route returns 200.
- The query names are case sensitive. `DateFrom` and `DateTo` filter. The lowercase `dateFrom` and `dateTo`, used in the page's sample URL, are ignored without an error, and so is the API page's `Offset` and `Limit`; the working names are `offset` and `limit`.
- Dates are sent in UTC as `yyyy-MM-ddTHH:mm:ssZ`. The API rejects a value without the `Z` or without a time with HTTP 400 "Failed to convert 'DateFrom'". A date given without a time zone, such as `'2026-10-01'`, is read as local time and converted.
- With no dates the API returns the last day. The command sends that window explicitly: `DateFrom` one day before the call and `DateTo` at the call.
- When only `-DateFrom` is given, the command sends `DateTo` as the time of the call. New audit rows, including rows the API writes for API reads, are added at the top of the list while paging, so an open-ended window would shift `offset` pages and repeat rows. A fixed window pages without repeats.
- When only `-DateTo` is given, only `DateTo` is sent. Live, this returned fewer rows than a window with both dates, so give both for a full range.
- Paging uses `offset` and `limit` and stops on a short page. `limit` above 500 returns HTTP 400 `EPM000002E` "must be less than or equal to 500". The response's `TotalCount` is the number of rows in the window.
- `Feature` values seen live include `POLICIES`, `ENDPOINT`, `EVENTS`, and `VIDEO_AUDIT`.
