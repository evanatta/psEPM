# Get-EPMVideo

Searches the recorded session videos in a set.

API: `POST /Sets/{SetId}/Videos/Search?limit=<n>&nextCursor=<cursor>` with a JSON body

| Parameter | Description |
| --- | --- |
| SetId | Set ID, pipeline by property name |
| Filter | Filter string, for example `startTime GE 2026-10-01T00:00:00Z` or `videoStatus EQ "Video Available"` |
| PageSize | 1 to 1000, default 1000 |
| First | Stop after this many results |

Output: `psEPM.Video` rows, the API video as returned. The API page lists `videoId`, `agentID`, `videoName`, `platform`, `policyName`, `policyId`, `username`, `computerName`, `application`, `startTime`, `endTime`, `durationMilliSec`, `locationType`, `videoPath`, `videoSize`, `status`, and `videoStatusDetails`. If the row has no `setId`, `SetId` is added.

Examples:

```powershell
Get-EPMVideo -SetId $setId
Get-EPMSet -Name 'Lab*' | Get-EPMVideo -Filter 'startTime GE 2026-10-01T00:00:00Z' -First 50
```

Notes:

- Video rows can hold user and computer names. Treat output as personal data.
- The method is `POST` with `Content-Type: application/json`, as the API page now shows. `GET` returns HTTP 405. With no `-Filter` the body is `{}`. A blank `-Filter` is not sent.
- Filter fields from the API page include `videoId`, `computerName`, `application`, `startTime` (`GE`, `LE`, unquoted UTC time), `locationType`, and `videoStatus`. An unknown field returns HTTP 400 `EPM090005E` "Videos were not loaded, please try again".
- Paging uses `nextCursor`, starting with `start`, URL-encoded, with the same stop rules as the event searches: stop at `filteredCount`, on an empty cursor, or when the same cursor or page comes back, with a warning if fewer than `filteredCount` came back. No set in testing held videos, so whether the cursor advances is unconfirmed. Keep `-PageSize` at 1000, the most the API returns in one request.
- Deleting videos has no command. `DELETE /Sets/{SetId}/Videos` answers (HTTP 404 for an unknown `videoId`, HTTP 400 `EPM090006E` for an empty filter), but no test set held a video, so a delete has not been confirmed.
