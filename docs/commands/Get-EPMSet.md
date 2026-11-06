# Get-EPMSet

Lists the sets the session can see. API: `GET /API/Sets` (paged, limit 1000).

| Parameter | Description |
| --- | --- |
| Name | Wildcard name filter, applied locally |
| SetId | One or more set IDs, accepts pipeline input by property name |

Output adds `SetId` (same as `Id`) so results pipe straight into other commands.

`GET /Sets/{SetId}` returns 404 on the tested tenant, so `-SetId` filters the list instead.
