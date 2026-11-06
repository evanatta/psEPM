# Get-EPMSignInAudit

Searches the detailed endpoint sign-in audit events in a set.

API: `POST /Sets/{SetId}/signinaudits/search?limit=<n>&nextCursor=<cursor>`

| Parameter | Description |
| --- | --- |
| SetId | Set ID, pipeline by property name |
| DateFrom | Adds `arrivalTime GE <UTC time>`. Optional |
| DateTo | Adds `arrivalTime LE <UTC time>`. Optional |
| Filter | Raw filter string, joined to the other clauses with `AND` |
| PageSize | 1 to 1000, default 1000 |
| First | Stop after this many results |

Output: `psEPM.SignInAudit` rows, the API sign-in event as returned. The API page lists fields such as `loginResult`, `loginType`, `loginProtocol`, `authenticationMethod`, `platform`, `policyName`, `newUser`, `failReason`, `failReasonCode`, and `arrivalTime`. If the row has no `setId`, `SetId` is added. An existing `setId` is kept.

Examples:

```powershell
Get-EPMSignInAudit -SetId $setId -DateFrom (Get-Date).AddDays(-7) -First 50
Get-EPMSignInAudit -SetId $setId -DateFrom '2026-10-01' -Filter 'loginResult EQ "false"'
Get-EPMSet -Name 'Lab*' | Get-EPMSignInAudit -Filter 'platform EQ "EPMP_WINDOWS"' -First 100
```

Notes:

- Rows can hold user and computer names. Treat output as personal data.
- `DateFrom` and `DateTo` filter on `arrivalTime`, the time the service received the audit, sent unquoted as `yyyy-MM-ddTHH:mm:ssZ` in UTC. A date without a time zone, such as `'2026-10-01'`, is read as local time. The filter table on the API page doesn't list `arrivalTime`, but it is accepted. The page lists `timeLast` (the event time) with a quoted value, for example `-Filter 'timeLast GE "2026-10-01T00:00:00Z"'`, which is also accepted.
- `DateFrom` is not required. With no filter the body is `{}`. An empty or blank `-Filter` is not sent.
- `loginResult` is compared with a quoted value: `loginResult EQ "true"` or `loginResult EQ "false"`.
- There is no `-EventType`. `eventType IN ...` returns HTTP 400 `EPM050015E` on this API, as does any unknown field.
- Paging uses `nextCursor`, starting with `start`, URL-encoded, with the same stop rules as the other event searches: stop at `filteredCount`, on an empty cursor, or when the same cursor or page comes back, with a warning if fewer than `filteredCount` came back. The API page's sample request sends `offset`, and `offset=0` is accepted. No set in testing held sign-in audits, so whether the cursor advances is unconfirmed.
- No API returns one sign-in audit by ID.
