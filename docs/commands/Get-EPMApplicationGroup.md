# Get-EPMApplicationGroup

Searches application groups in a set, or gets one application group's details.

APIs: `POST /Sets/{SetId}/Policies/ApplicationGroups/Search` and `GET /Sets/{SetId}/Policies/ApplicationGroups/{ApplicationGroupId}`.

| Parameter | Description |
| --- | --- |
| SetId | Set ID, pipeline by property name |
| ApplicationGroupId | Application group ID for details, pipeline by property name. Alias `PolicyId`, so search rows pipe in |
| Filter | Raw filter string |
| Name | Adds `PolicyName CONTAINS "<value>"` |
| SortBy, SortDirection | Sort order |
| PageSize | 1 to 1000, default 1000 |
| First | Stop after this many results |

Output:

- Search: `psEPM.ApplicationGroup` rows with the API fields (`PolicyId`, `PolicyName`, `PolicyType`, `Description`, `CreatedDate`, `ModifiedDate`, and others) plus `SetId` and `ApplicationGroupId`.
- Details: `psEPM.ApplicationGroupDetail`, the API wrapper `{ CreatedDate, ModifiedDate, Order, OsType, Policy }` plus `SetId`, `ApplicationGroupId`, and `PolicyId`. `Policy` holds `Id`, `Name`, `PolicyType` (14), `Description`, `Applications`, and `LinkedAgentPolicies`.

Examples:

```powershell
Get-EPMApplicationGroup -SetId $setId -Name 'Allow'
Get-EPMApplicationGroup -SetId $setId -Name 'Allow' | Get-EPMApplicationGroup
```

Notes:

- The search filter field is `PolicyName`. `Name CONTAINS` returns HTTP 400.
- An empty body does not return every group. Rows of several other policy types are returned, and some application groups that appear in an export are missing. Search by name to find a specific group.
- Use these routes for application groups. `GET /Policies/Server/{Id}` with an application group ID returns HTTP 400 "cannot use policies' API for application groups".
