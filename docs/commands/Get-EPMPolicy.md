# Get-EPMPolicy

Searches policies in a set, or gets one policy's details.

APIs: `POST /Sets/{SetId}/Policies/Server/Search` and `GET /Sets/{SetId}/Policies/Server/{PolicyId}`.

| Parameter | Description |
| --- | --- |
| SetId | Set ID, pipeline by property name |
| PolicyId | Policy ID for details, pipeline by property name |
| Filter | Raw filter string |
| Name | Adds `PolicyName CONTAINS "<value>"` |
| All | Adds `PolicyGroupType EQ Computer`, which returns every policy in the set, including trusted sources, application groups, and the agent configuration. Cannot be combined with a `PolicyType` filter |
| SortBy, SortDirection | Sort order |
| PageSize | 1 to 1000, default 1000 |
| First | Stop after this many results |

An empty body, or an empty `filter`, does not return every policy. Live (2026-11-16) it returned 16 of 40 objects in one set and 34 of 76 in another. Trusted source policies (types 33, 34, 35), application groups (14, 16, 19, 21, 43), and the agent configuration (45) were left out, although `TotalCount` counts them. Use `-All` to get everything. The API rejects a filter with both `PolicyType` and `PolicyGroupType` (HTTP 400), so `-All` refuses a `PolicyType` filter. `GET` on the search URL returns 400.

Example:

```powershell
Get-EPMPolicy -SetId $setId -All | Group-Object PolicyType
```

Search results carry `PolicyId` from the API. Details by ID are the API wrapper `{ CreatedDate, ModifiedDate, Order, OsType, Policy }` with the added `SetId` and `PolicyId` properties, so both pipe into `Set-EPMPolicy` and `Remove-EPMPolicy`.
