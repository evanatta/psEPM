# Get-EPMEndpointPackage

Lists the agent packages available for endpoints in a set. API: `POST /Sets/{SetId}/Endpoints/Packages`.

| Parameter | Description |
| --- | --- |
| SetId | Set ID, pipeline by property name |
| EndpointId | One or more endpoint IDs, pipeline by property name, sent as `id IN <id>,<id>` |
| Filter | Raw endpoint filter string, for example `connectionStatus EQ Connected` |
| Name | Adds `name CONTAINS "<value>"` |
| Platform | Windows, MacOS, Linux. One value is sent as `platform EQ`, more than one as `platform IN` |

Output adds `SetId`, `PackageId`, `Version` and `FilteredCount` (the number of endpoints that matched the filter).

Notes:

- `POST` only. `GET` returns 405.
- `{}` returns all packages for all endpoints. No body returns 400 `Missing mandatory parameter - filter.`
- The response count field is `filteredCount`. The docs show `filterCount` in one place and describe it as the Linux public key.
- `packageType` is `null` in live responses.
- A set with no endpoints returns no packages.
- Not paged. `offset` and `limit` are ignored.
