# Get-EPMEndpointInventory

Gets one inventory section for many endpoints in a set.

API: `POST /Sets/{SetId}/Endpoints/inventory/{InventoryType}` with `limit` and `offset` paging.

| Parameter | Description |
| --- | --- |
| SetId | Set ID, pipeline by property name |
| InventoryType | OsInfo, Hardware, Network, DomainInfo, TimeAndDate, UserGroups, InstalledPrograms. One request per type |
| EndpointId | Adds `endpointId EQ "<value>"`, pipeline by property name |
| Filter | Raw filter string, for example `platform EQ Windows`. Joined to the EndpointId clause with `AND` |
| PageSize | 1 to 1000, default 1000 |
| First | Stop after this many results for each inventory type |

Output: one `psEPM.EndpointInventory` object per endpoint and inventory type. Each has the endpoint fields (`id`, `name`, `platform`, `connectionStatus`, `version`, and others), an `inventory` property that holds only the requested section, and the added `SetId`, `EndpointId`, and `InventoryType` properties.

Examples:

```powershell
Get-EPMSet -Name 'Lab*' | Get-EPMEndpointInventory -InventoryType OsInfo
Get-EPMEndpointInventory -SetId $setId -InventoryType Hardware, Network -Filter 'platform EQ Windows'
Get-EPMSet -Name 'Lab*' | Get-EPMEndpoint -Name 'PC01' | Get-EPMEndpointInventory -InventoryType InstalledPrograms
```

Notes:

- The `filter` body field is required. An empty string returns all endpoints. A body without `filter` returns HTTP 400.
- The API reference shows the result as a single object. The API returns a JSON array of endpoints.
- Filter on `endpointId`, as the reference says. `id EQ "<value>"` returns HTTP 500.
- The inventory type names differ from `Get-EPMEndpoint -InventoryType`, which uses `UserGroupsInfo` and `InstalledProgramsInfo`. The returned section names are `osInfo`, `hardware`, `network`, `domainInfo`, `timeAndDate`, `userGroupsInfo`, and `installedProgramsInfo`.
- `InstalledPrograms` usually returns Windows endpoints only.
- The API default page size is 100. This command requests 1000 per page and follows `offset` until a short page.
