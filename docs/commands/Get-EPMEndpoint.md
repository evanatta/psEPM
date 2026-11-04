# Get-EPMEndpoint

Searches endpoints in a set, or gets one endpoint's details.

APIs: `POST /Sets/{SetId}/Endpoints/search` and `POST /Sets/{SetId}/Endpoints/{EndpointId}/search`.

| Parameter | Description |
| --- | --- |
| SetId | Set ID, pipeline by property name |
| EndpointId | Endpoint ID for details, pipeline by property name |
| InventoryType | OsInfo, Hardware, Network, DomainInfo, TimeAndDate, UserGroupsInfo, InstalledProgramsInfo |
| Filter | Raw filter string, for example `version CONTAINS "26.8"` |
| Name | Adds `name CONTAINS "<value>"` |
| Platform | Windows, MacOS, Linux |
| SortBy, SortDirection | Sort order |
| PageSize | 1 to 1000, default 1000 |
| First | Stop after this many results |

Notes:

- Filter values are case sensitive.
- `InventoryType` is sent as `inventoryType IN OsInfo,Hardware`. One quoted list returns HTTP 500.
- An unknown endpoint ID returns HTTP 500, not 404.
