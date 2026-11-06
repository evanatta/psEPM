# Get-EPMEndpointGroup

Searches endpoint groups in a set.

API: `POST /v2/Sets/{SetId}/Endpoints/groups/search` with `limit`, `offset`, `sortBy`, and `sortDir`. If v2 returns HTTP 404, the command uses the deprecated v1 route `POST /Sets/{SetId}/Endpoints/groups/search`, which returns a plain JSON array. Other errors are not retried on v1.

| Parameter | Description |
| --- | --- |
| SetId | Set ID, pipeline by property name |
| GroupId | One or more group IDs, pipeline by property name. One ID adds `id EQ "<value>"`, several add `id IN a,b` |
| Name | Adds `name CONTAINS "<value>"` |
| Type | Static or Dynamic. Adds `type EQ <value>` |
| Filter | Raw filter string, for example `description CONTAINS "lab"` |
| SortBy | name or Type, default name |
| SortDirection | asc or desc, default desc (the API default) |
| PageSize | 1 to 1000, default 1000 |
| First | Stop after this many results |

Clauses are joined with `AND`. Filter fields are `id`, `name`, `type`, and `description`.

Output: one `psEPM.EndpointGroup` object per group with `id`, `name`, `type`, `description`, `membersCount`, `filter` (the query of a dynamic group), and `updated`, plus the added `SetId` and `GroupId` properties.

Examples:

```powershell
Get-EPMSet -Name 'Lab*' | Get-EPMEndpointGroup
Get-EPMEndpointGroup -SetId $setId -Type Dynamic -Name 'Windows'
```

Notes:

- The `filter` body field is required. An empty string returns all groups. A body without `filter` returns HTTP 400.
- No API returns the members of a group. The search returns only `membersCount`.
- The v2 response wrapper is `{ endpointGroups, filteredCount, returnedCount, resultsCount }`. `resultsCount` is not in the API reference.
- The API default page size is 100. This command requests 1000 per page and follows `offset` until a short page.
