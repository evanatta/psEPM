# Get-EPMAgentConfiguration

Searches agent configurations in a set, gets one configuration's details, or gets the product default configuration.

APIs:

- Search: `POST /Sets/{SetId}/Policies/AgentConfiguration/Search` with `{}` for all
- Details: `GET /Sets/{SetId}/Policies/AgentConfiguration/{AgentConfigurationId}`
- Default: `GET /Sets/{SetId}/Policies/AgentConfiguration/Default`

| Parameter | Description |
| --- | --- |
| SetId | Set ID, pipeline by property name |
| AgentConfigurationId | Configuration ID for details, pipeline by property name. Alias `PolicyId`, so search rows pipe in |
| Default | Gets the product default configuration |
| Filter | Raw filter string (search) |
| Name | Adds `PolicyName CONTAINS "<value>"` (search) |
| SortBy, SortDirection | Sort order (search) |
| PageSize | 1 to 1000, default 1000 (search) |
| First | Stop after this many results (search) |

Output:

- Search: `psEPM.AgentConfiguration` rows (`PolicyId`, `PolicyName`, `PolicyType`, `IsActive`, `IsAppliedToAllComputers`, and others) plus `SetId` and `AgentConfigurationId`.
- Details: `psEPM.AgentConfigurationDetail`, the API wrapper `{ CreatedDate, ModifiedDate, Order, OsType, Policy }` plus `SetId`, `AgentConfigurationId`, and `PolicyId`.
- Default: `psEPM.AgentConfigurationDefinition`, the configuration itself (`Id`, `Name`, `PolicyType`, `Action`, `AgentBehavior`, `DataCollection`, `EndpointUi`, `ExtendedProtection`, and other sections) plus `SetId` and `AgentConfigurationId`.

Examples:

```powershell
Get-EPMSet -Name 'Lab*' | Get-EPMAgentConfiguration
Get-EPMAgentConfiguration -SetId $setId -Name 'General' | Get-EPMAgentConfiguration
Get-EPMAgentConfiguration -SetId $setId -Default
```

Notes:

- The API reference URL for the default configuration repeats a segment (`.../AgentConfiguration/AgentConfiguration/Default`), which returns HTTP 404. The working path has one `AgentConfiguration` segment.
- `-Default` returns the product default template, not the set's current settings. Its `Id` is the set ID and its `Name` is "General configuration", like the set's real General configuration, but sections such as `AgentBehavior`, `DataCollection`, and `ExtendedProtection` differ. For the set's current settings, get the details of the General configuration row from the search.
- Search rows report `PolicyType` 45. Details and the default report 44 for the same configuration.
- The General configuration's ID is the set ID. A computer-specific configuration's ID is the endpoint ID.
- The search filter field is `PolicyName`. `Name CONTAINS` returns HTTP 400.
- An unknown ID returns HTTP 404 `EPM060001E` "Policy not found."
