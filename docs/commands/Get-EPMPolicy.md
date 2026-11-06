# Get-EPMPolicy

Searches policies in a set, or gets one policy's details.

APIs: `POST /Sets/{SetId}/Policies/Server/Search` and `GET /Sets/{SetId}/Policies/Server/{PolicyId}`.

| Parameter | Description |
| --- | --- |
| SetId | Set ID, pipeline by property name |
| PolicyId | Policy ID for details, pipeline by property name |
| Filter | Raw filter string |
| Name | Adds `PolicyName CONTAINS "<value>"` |
| SortBy, SortDirection | Sort order |
| PageSize | 1 to 1000, default 1000 |
| First | Stop after this many results |

An empty body returns all policies. `GET` on the search URL returns 400.

Search results carry `PolicyId` from the API. Details by ID are the API wrapper `{ CreatedDate, ModifiedDate, Order, OsType, Policy }` with the added `SetId` and `PolicyId` properties, so both pipe into `Set-EPMPolicy` and `Remove-EPMPolicy`.
